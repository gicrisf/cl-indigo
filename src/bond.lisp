;;;; bond.lisp - Bond property functions and predicates

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Bond Atoms
;;;; =========================================================================

(defun bond-source (bond)
  "Get source atom handle of BOND.
Returns an atom handle that should NOT be freed (owned by molecule)."
  (cl-indigo.cffi::%indigo-source bond))

(defun bond-destination (bond)
  "Get destination atom handle of BOND.
Returns an atom handle that should NOT be freed (owned by molecule)."
  (cl-indigo.cffi::%indigo-destination bond))

;;;; =========================================================================
;;;; Bond Order
;;;; =========================================================================

(defun bond-order (bond)
  "Get bond order of BOND as keyword.
Returns :QUERY, :SINGLE, :DOUBLE, :TRIPLE, or :AROMATIC.

Example:
  (with-molecule (mol \"C=C\")  ; Ethene
    (with-bonds-stream (stream mol)
      (bond-order (stream-first stream))))
  => :DOUBLE"
  (bond-order-keyword (cl-indigo.cffi::%indigo-bond-order bond)))

;;;; =========================================================================
;;;; Bond Order Predicates
;;;; =========================================================================

(defun bond-single-p (bond)
  "Return T if BOND is a single bond."
  (eq (bond-order bond) :single))

(defun bond-double-p (bond)
  "Return T if BOND is a double bond."
  (eq (bond-order bond) :double))

(defun bond-triple-p (bond)
  "Return T if BOND is a triple bond."
  (eq (bond-order bond) :triple))

(defun bond-aromatic-p (bond)
  "Return T if BOND is an aromatic bond."
  (eq (bond-order bond) :aromatic))

;;;; =========================================================================
;;;; Bond Stereochemistry
;;;; =========================================================================

(defun bond-stereo (bond)
  "Get stereochemistry of BOND as keyword.
Returns :NONE, :EITHER, :UP, :DOWN, :CIS, or :TRANS.

:UP and :DOWN refer to wedge/dash notation for chiral centers.
:CIS and :TRANS refer to double bond geometry (Z/E).

Example:
  (with-molecule (mol \"C/C=C/C\")  ; trans-2-butene
    (with-bonds-stream (stream mol)
      ;; Find the double bond
      (stream-first
       (stream-filter #'bond-double-p stream))))
  ;; The stereo is on the single bonds adjacent to double bond"
  (bond-stereo-keyword (cl-indigo.cffi::%indigo-bond-stereo bond)))

;;;; =========================================================================
;;;; Bond Stereo Predicates
;;;; =========================================================================

(defun bond-has-stereo-p (bond)
  "Return T if BOND has stereochemistry information."
  (not (eq (bond-stereo bond) :none)))

(defun bond-up-p (bond)
  "Return T if BOND is a wedge (up) bond."
  (eq (bond-stereo bond) :up))

(defun bond-down-p (bond)
  "Return T if BOND is a dashed (down) bond."
  (eq (bond-stereo bond) :down))

(defun bond-cis-p (bond)
  "Return T if BOND has cis (Z) stereochemistry."
  (eq (bond-stereo bond) :cis))

(defun bond-trans-p (bond)
  "Return T if BOND has trans (E) stereochemistry."
  (eq (bond-stereo bond) :trans))
