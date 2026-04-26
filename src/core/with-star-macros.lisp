;;;; with-star-macros.lisp - Meta-macro for generating sequential binding variants

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Meta-Macro Definition
;;;; =========================================================================

(defmacro define-with-star (base-name)
  "Generate a sequential binding version (*) of a with- macro.

Given BASE-NAME (e.g., \"molecule\"), creates WITH-MOLECULE* that
wraps WITH-MOLECULE with sequential binding semantics (like LET*).

The generated macro accepts multiple bindings and evaluates them
sequentially, ensuring proper cleanup for each resource even if
a later binding fails.

Example usage:
  (define-with-star \"molecule\")
  ;; Creates WITH-MOLECULE* from WITH-MOLECULE

The generated macro can then be used like:
  (with-molecule* ((mol1 \"CCO\")
                   (mol2 \"c1ccccc1\"))
    (list (molecular-weight mol1)
          (molecular-weight mol2)))"
  (let ((base-macro (intern (format nil "WITH-~A" (string-upcase base-name))))
        (star-macro (intern (format nil "WITH-~A*" (string-upcase base-name)))))
    `(defmacro ,star-macro (bindings &body body)
       ,(format nil "Sequential binding version of ~A.~%~
                     BINDINGS is a list of bindings: ((VAR1 ARG1...) (VAR2 ARG2...) ...)~%~
                     Bindings are evaluated sequentially (like LET*) with automatic cleanup."
                base-macro)
       (if (null bindings)
           `(progn ,@body)
           `(,',base-macro ,(car bindings)
              (,',star-macro ,(cdr bindings)
                ,@body))))))

;;;; =========================================================================
;;;; Generate Star Variants
;;;; =========================================================================

;;; Molecule macros
(define-with-star "molecule")
(define-with-star "mol-file")
(define-with-star "query")
(define-with-star "smarts")
(define-with-star "fingerprint")
(define-with-star "matcher")
(define-with-star "reaction")
(define-with-star "rxn-file")

;;; Iterator macros
(define-with-star "atoms-iterator")
(define-with-star "bonds-iterator")
(define-with-star "neighbors-iterator")
(define-with-star "components-iterator")
(define-with-star "sssr-iterator")
(define-with-star "stereocenters-iterator")
(define-with-star "reactants-iterator")
(define-with-star "products-iterator")

;;; Stream macros (defined in streams.lisp, star variants here)
(define-with-star "atoms-stream")
(define-with-star "bonds-stream")
