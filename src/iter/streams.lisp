;;;; streams.lisp - Lazy stream abstraction

(in-package #:cl-indigo)

;; Note: This implementation uses a defstruct (lazy-stream) with explicit fields
;; (:thunk, :forced, :cached-value) rather than the plain closure approach
;; used in emacs-indigo (indigo-stream.el). Both achieve lazy evaluation with
;; memoization, but the struct approach provides:
;;   - Compile-time type checking
;;   - Explicit documentation in the struct
;;   - Easier debugging (printable representation)
;;
;; The emacs-indigo version uses captured let variables in a lambda,
;; which works in Elisp's dynamic scoping but can have edge cases.
;; The struct approach is more idiomatic for Common Lisp.

;;;;; Lazy Stream Data Structure
;;;;; ========================================================================= 

(defstruct (lazy-stream
            (:constructor make-lazy-stream (thunk))
            (:copier nil))
  "A lazy stream with memoization.
The stream is either empty (NIL) or contains a thunk that when forced
produces (value . next-stream) or NIL."
  (thunk nil :type (or null function))
  (forced nil :type boolean)
  (cached-value nil))

;;;; =========================================================================
;;;; Stream Creation
;;;; =========================================================================

(defun indigo-stream (iterator &optional tracker-fn)
  "Create a lazy stream from an Indigo ITERATOR.

If TRACKER-FN is provided, it will be called with each element when
it's first forced from the iterator. This is useful for tracking
elements for later cleanup.

Returns a lazy stream that, when forced, produces:
  (element . next-stream) - if more elements
  NIL                     - if iterator is exhausted

The stream does NOT take ownership of the iterator - caller must free it.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-iterator (iter mol)
      (let ((stream (indigo-stream iter)))
        (stream-first stream))))
  => <atom handle>"
  (when iterator
    (make-lazy-stream
     (lambda ()
       (let ((element (indigo-next iterator)))
         (when element
           ;; Track element if tracker provided
           (when tracker-fn
             (funcall tracker-fn element))
           ;; Return (element . next-stream)
           (cons element (indigo-stream iterator tracker-fn))))))))

;;;; =========================================================================
;;;; Stream Operations
;;;; =========================================================================

(defun stream-force (stream)
  "Force a lazy STREAM, returning (value . next-stream) or NIL.
The result is memoized - subsequent calls return the cached value."
  (when (and stream (lazy-stream-p stream))
    (unless (lazy-stream-forced stream)
      (setf (lazy-stream-cached-value stream)
            (when (lazy-stream-thunk stream)
              (funcall (lazy-stream-thunk stream))))
      (setf (lazy-stream-forced stream) t))
    (lazy-stream-cached-value stream)))

(defun stream-first (stream)
  "Force STREAM and return the first element, or NIL if empty.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (atom-symbol (stream-first stream))))
  => \"C\""
  (let ((forced (stream-force stream)))
    (when forced (car forced))))

(defun stream-rest (stream)
  "Force STREAM and return the rest of the stream, or NIL if empty.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (let ((rest (stream-rest stream)))
        (atom-symbol (stream-first rest)))))
  => \"C\" (second atom)"
  (let ((forced (stream-force stream)))
    (when forced (cdr forced))))

(defun stream-empty-p (stream)
  "Check if STREAM is empty."
  (or (null stream)
      (not (lazy-stream-p stream))
      (null (stream-force stream))))

;;;; =========================================================================
;;;; Stream Combinators
;;;; =========================================================================

(defun stream-map (fn stream)
  "Map FN over elements in STREAM, returning a new lazy stream.

This is a lazy implementation: FN is only called when accessing
elements via STREAM-FIRST or advancing via STREAM-REST.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (stream-collect (stream-map #'atom-symbol stream))))
  => (\"C\" \"C\" \"O\")"
  ;; Return a lazy stream - emptiness is checked inside the thunk
  (when stream
    (make-lazy-stream
     (lambda ()
       (let ((forced (stream-force stream)))
         (when forced
           (cons (funcall fn (car forced))
                 (stream-map fn (cdr forced)))))))))

(defun stream-filter (predicate stream)
  "Filter STREAM by PREDICATE, returning a new lazy stream.

This is a lazy implementation: PREDICATE is only called when
advancing through the stream.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (let ((carbons (stream-filter
                      (lambda (atom) (string= (atom-symbol atom) \"C\"))
                      stream)))
        (stream-collect (stream-map #'atom-symbol carbons)))))
  => (\"C\" \"C\")"
  ;; Return a lazy stream - emptiness is checked inside the thunk
  (when stream
    (make-lazy-stream
     (lambda ()
       ;; Search for first matching element
       (loop for current = stream then (stream-rest current)
             while (not (stream-empty-p current))
             for value = (stream-first current)
             when (funcall predicate value)
               return (cons value (stream-filter predicate (stream-rest current)))
             finally (return nil))))))

(defun stream-take (n stream)
  "Take first N elements from STREAM, returning a new lazy stream.

This is a lazy implementation: elements are only forced when accessed.

Example:
  (with-molecule (mol \"CCCCCC\")  ; Hexane
    (with-atoms-stream (stream mol)
      (stream-collect (stream-take 3 stream))))
  => (<atom1> <atom2> <atom3>)"
  ;; Return a lazy stream - emptiness is checked inside the thunk
  (when (and stream (> n 0))
    (make-lazy-stream
     (lambda ()
       (let ((forced (stream-force stream)))
         (when forced
           (cons (car forced)
                 (stream-take (1- n) (cdr forced)))))))))

(defun stream-fold (fn init stream)
  "Fold STREAM from left to right using FN with initial value INIT.

This is a consuming operation: forces the entire stream and returns
a single accumulated result. FN is called with two arguments:
  (FN accumulator element)

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (stream-fold (lambda (acc atom)
                     (+ acc (atom-index atom)))
                   0
                   stream)))
  => 3  ; (0 + 1 + 2)"
  (loop with acc = init
        until (stream-empty-p stream)
        do (setf acc (funcall fn acc (stream-first stream))
                 stream (stream-rest stream))
        finally (return acc)))

(defun stream-collect (stream)
  "Collect all elements from STREAM into a list.

This is a consuming operation that forces the entire stream.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (stream-collect (stream-map #'atom-symbol stream))))
  => (\"C\" \"C\" \"O\")"
  (nreverse
   (stream-fold (lambda (acc x) (cons x acc)) nil stream)))

;;;; =========================================================================
;;;; Stream Resource Management Macros
;;;; =========================================================================

(defmacro with-stream-from-iterator ((stream-var iterator-var) &body body)
  "Create a stream from an iterator with automatic element cleanup.

STREAM-VAR is bound to the stream.
All elements forced from the stream are tracked and automatically
freed when exiting the scope.

The iterator itself should be managed by an outer WITH-*-ITERATOR macro.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-iterator (iter mol)
      (with-stream-from-iterator (stream iter)
        (stream-collect (stream-map #'atom-symbol stream)))))"
  (with-gensyms (tracked-elements element)
    `(let ((,tracked-elements nil))
       (let ((,stream-var
               (indigo-stream ,iterator-var
                              (lambda (,element)
                                (push ,element ,tracked-elements)))))
         (unwind-protect
             (progn ,@body)
           ;; Free all tracked elements
           (dolist (,element ,tracked-elements)
             (when ,element
               (cl-indigo.cffi::%indigo-free ,element))))))))

;;; High-level stream macros (combine iterator + stream)

(defmacro with-atoms-stream ((stream-var molecule) &body body)
  "Create a stream from atoms iterator with automatic cleanup.

Both the iterator and all accessed atoms are automatically freed.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (stream-collect (stream-map #'atom-symbol stream))))
  => (\"C\" \"C\" \"O\")"
  (with-gensyms (iter-var)
    `(with-atoms-iterator (,iter-var ,molecule)
       (with-stream-from-iterator (,stream-var ,iter-var)
         ,@body))))

(defmacro with-bonds-stream ((stream-var molecule) &body body)
  "Create a stream from bonds iterator with automatic cleanup.

Both the iterator and all accessed bonds are automatically freed.

Example:
  (with-molecule (mol \"CCO\")
    (with-bonds-stream (stream mol)
      (stream-collect (stream-map #'bond-order stream))))
  => (:SINGLE :SINGLE)"
  (with-gensyms (iter-var)
    `(with-bonds-iterator (,iter-var ,molecule)
       (with-stream-from-iterator (,stream-var ,iter-var)
         ,@body))))
