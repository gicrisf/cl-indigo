;;;; iterators.lisp - Iterator wrapper functions

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Iterator Creation
;;;; =========================================================================

(defun iterate-atoms (molecule)
  "Create an iterator over atoms in MOLECULE.
Returns an iterator handle that must be freed.
Use WITH-ATOMS-ITERATOR for automatic cleanup.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-iterator (atoms mol)
      (loop for atom = (indigo-next atoms)
            while atom
            collect (atom-symbol atom))))
  => (\"C\" \"C\" \"O\")"
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-atoms molecule)
   "iterate-atoms"))

(defun iterate-bonds (molecule)
  "Create an iterator over bonds in MOLECULE.
Returns an iterator handle that must be freed.
Use WITH-BONDS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-bonds molecule)
   "iterate-bonds"))

(defun iterate-neighbors (atom)
  "Create an iterator over neighbors of ATOM.
Returns an iterator handle that must be freed.
Use WITH-NEIGHBORS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-neighbors atom)
   "iterate-neighbors"))

(defun iterate-components (molecule)
  "Create an iterator over connected components in MOLECULE.
Each component is a separate molecular fragment.
Returns an iterator handle that must be freed.
Use WITH-COMPONENTS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-components molecule)
   "iterate-components"))

(defun iterate-sssr (molecule)
  "Create an iterator over SSSR rings in MOLECULE.
SSSR = Smallest Set of Smallest Rings.
Returns an iterator handle that must be freed.
Use WITH-SSSR-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-sssr molecule)
   "iterate-sssr"))

(defun iterate-stereocenters (molecule)
  "Create an iterator over stereocenters in MOLECULE.
Returns an iterator handle that must be freed.
Use WITH-STEREOCENTERS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-stereocenters molecule)
   "iterate-stereocenters"))

(defun iterate-reactants (reaction)
  "Create an iterator over reactants in REACTION.
Returns an iterator handle that must be freed.
Use WITH-REACTANTS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-reactants reaction)
   "iterate-reactants"))

(defun iterate-products (reaction)
  "Create an iterator over products in REACTION.
Returns an iterator handle that must be freed.
Use WITH-PRODUCTS-ITERATOR for automatic cleanup."
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-products reaction)
   "iterate-products"))

;;;; =========================================================================
;;;; Iterator Advancement
;;;; =========================================================================

(defun indigo-next (iterator)
  "Get the next item from ITERATOR.
Returns item handle, or NIL if iterator is exhausted.
Signals INDIGO-ERROR on failure.

Note: Each returned item is a new handle that should be freed
when no longer needed. Use WITH-*-STREAM macros for automatic cleanup."
  (let ((result (cl-indigo.cffi::%indigo-next iterator)))
    (cond
      ((cl-indigo.cffi::handle-valid-p result) result)
      ((cl-indigo.cffi::handle-end-p result) nil)
      ((cl-indigo.cffi::handle-error-p result)
       (error 'indigo-error
              :message (format nil "indigo-next: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t nil))))

;;;; =========================================================================
;;;; Iterator Utilities
;;;; =========================================================================

(defun indigo-map (fn iterator)
  "Apply FN to each item in ITERATOR, collecting results.
Items are automatically freed after FN is applied.

This is a consuming operation that exhausts the iterator.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-iterator (atoms mol)
      (indigo-map #'atom-symbol atoms)))
  => (\"C\" \"C\" \"O\")"
  (loop for item = (indigo-next iterator)
        while item
        collect (unwind-protect
                    (funcall fn item)
                  (cl-indigo.cffi::%indigo-free item))))
