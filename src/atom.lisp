;;;; atom.lisp - Atom property functions and predicates

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Basic Atom Properties
;;;; =========================================================================

(defun atom-symbol (atom)
  "Get element symbol of ATOM.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (atom-symbol (stream-first stream))))
  => \"C\""
  (cl-indigo.cffi::%indigo-symbol atom))

(defun atom-index (atom)
  "Get index of ATOM (0-based).

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-stream (stream mol)
      (atom-index (stream-first stream))))
  => 0"
  (cl-indigo.cffi::%indigo-index atom))

;;;; =========================================================================
;;;; Charge
;;;; =========================================================================

(defun atom-charge (atom)
  "Get formal charge of ATOM.
Returns an integer: positive, negative, or zero.

Example:
  (with-molecule (mol \"[O-]CCO\")  ; Ethoxide
    (with-atoms-stream (stream mol)
      (atom-charge (stream-first stream))))
  => -1"
  (cffi:with-foreign-object (charge :int)
    (when (= 1 (cl-indigo.cffi::%indigo-get-charge atom charge))
      (cffi:mem-ref charge :int))))

;;;; =========================================================================
;;;; Coordinates
;;;; =========================================================================

(defun atom-xyz (atom)
  "Get XYZ coordinates of ATOM as a list (x y z).
Returns NIL if molecule has no coordinates.

Example:
  (with-molecule (mol \"CCO\")
    (layout mol)
    (with-atoms-stream (stream mol)
      (atom-xyz (stream-first stream))))
  => (0.0 1.5 0.0)  ; example coordinates"
  (let ((ptr (cl-indigo.cffi::%indigo-xyz atom)))
    (when (and ptr (not (cffi:null-pointer-p ptr)))
      (list (cffi:mem-aref ptr :float 0)
            (cffi:mem-aref ptr :float 1)
            (cffi:mem-aref ptr :float 2)))))

;;;; =========================================================================
;;;; Radical State
;;;; =========================================================================

(defun atom-radical (atom)
  "Get radical state of ATOM as keyword.
Returns :NONE, :SINGLET, :DOUBLET, or :TRIPLET.

Example:
  (with-molecule (mol \"[CH3]\")  ; Methyl radical
    (with-atoms-stream (stream mol)
      (atom-radical (stream-first stream))))
  => :DOUBLET"
  (cffi:with-foreign-object (radical :int)
    (if (= 1 (cl-indigo.cffi::%indigo-get-radical atom radical))
        (radical-keyword (cffi:mem-ref radical :int))
        :none)))

(defun atom-radical-electrons (atom)
  "Get number of radical electrons on ATOM.
Returns 0, 1, or 2.

Example:
  (with-molecule (mol \"[CH3]\")  ; Methyl radical
    (with-atoms-stream (stream mol)
      (atom-radical-electrons (stream-first stream))))
  => 1"
  (cffi:with-foreign-object (electrons :int)
    (if (= 1 (cl-indigo.cffi::%indigo-get-radical-electrons atom electrons))
        (cffi:mem-ref electrons :int)
        0)))

;;;; =========================================================================
;;;; Radical Predicates
;;;; =========================================================================

(defun atom-radical-p (atom)
  "Return T if ATOM has any radical state."
  (not (eq (atom-radical atom) :none)))

(defun atom-singlet-p (atom)
  "Return T if ATOM is a singlet radical (paired electrons)."
  (eq (atom-radical atom) :singlet))

(defun atom-doublet-p (atom)
  "Return T if ATOM is a doublet radical (one unpaired electron)."
  (eq (atom-radical atom) :doublet))

(defun atom-triplet-p (atom)
  "Return T if ATOM is a triplet radical (two unpaired electrons)."
  (eq (atom-radical atom) :triplet))
