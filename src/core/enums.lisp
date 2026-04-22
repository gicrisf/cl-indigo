;;;; enums.lisp - Keyword enums for bond orders, stereo, and radicals

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Bond Order Mapping
;;;; =========================================================================

(defparameter +bond-orders+
  '((0 . :query)
    (1 . :single)
    (2 . :double)
    (3 . :triple)
    (4 . :aromatic))
  "Mapping from Indigo bond order integers to keywords.
0 = query bond (in query molecules)
1 = single bond
2 = double bond
3 = triple bond
4 = aromatic bond")

(defun bond-order-keyword (code)
  "Convert integer CODE to bond order keyword."
  (cdr (assoc code +bond-orders+)))

(defun bond-order-code (keyword)
  "Convert KEYWORD to bond order integer code."
  (car (rassoc keyword +bond-orders+)))

;;;; =========================================================================
;;;; Bond Stereochemistry Mapping
;;;; =========================================================================

(defparameter +bond-stereos+
  '((0 . :none)
    (4 . :either)
    (5 . :up)
    (6 . :down)
    (7 . :cis)
    (8 . :trans))
  "Mapping from Indigo stereochemistry integers to keywords.
0 = no stereo
4 = either (wavy bond)
5 = up (wedge)
6 = down (dashed)
7 = cis (Z)
8 = trans (E)")

(defun bond-stereo-keyword (code)
  "Convert integer CODE to stereo keyword."
  (cdr (assoc code +bond-stereos+)))

(defun bond-stereo-code (keyword)
  "Convert KEYWORD to stereo integer code."
  (car (rassoc keyword +bond-stereos+)))

;;;; =========================================================================
;;;; Radical State Mapping
;;;; =========================================================================

(defparameter +radicals+
  '((0 . :none)
    (101 . :singlet)
    (102 . :doublet)
    (103 . :triplet))
  "Mapping from Indigo radical integers to keywords.
0 = no radical
101 = singlet (paired electrons)
102 = doublet (one unpaired electron)
103 = triplet (two unpaired electrons)")

(defun radical-keyword (code)
  "Convert integer CODE to radical keyword."
  (cdr (assoc code +radicals+)))

(defun radical-code (keyword)
  "Convert KEYWORD to radical integer code."
  (car (rassoc keyword +radicals+)))
