;;;; render.lisp - Rendering operations

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; File Rendering
;;;; =========================================================================

(defun render-to-file (object filename)
  "Render OBJECT to FILENAME.

The output format is determined by the file extension:
  .svg - SVG vector graphics
  .png - PNG raster image
  .pdf - PDF document

Example:
  (with-molecule (mol \"c1ccccc1\")
    (layout mol)
    (render-to-file mol \"benzene.svg\"))"
  (check-result
   (cl-indigo.cffi::%indigo-render-to-file object (namestring filename))
   "render-to-file"))

;;;; =========================================================================
;;;; Array Operations (for Grid Rendering)
;;;; =========================================================================

(defun create-array ()
  "Create an array for holding multiple objects.
Used for grid rendering of multiple molecules.
Returns an array handle that must be freed.

Example:
  (with-molecule* ((mol1 \"CCO\")
                   (mol2 \"c1ccccc1\"))
    (let ((arr (create-array)))
      (unwind-protect
          (progn
            (array-add arr mol1)
            (array-add arr mol2)
            ;; render grid...
            )
        (indigo-free arr))))"
  (check-handle
   (cl-indigo.cffi::%indigo-create-array)
   "create-array"))

(defun array-add (array object)
  "Add OBJECT to ARRAY.
Returns the index of the added object."
  (check-result
   (cl-indigo.cffi::%indigo-array-add array object)
   "array-add"))
