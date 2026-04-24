;;;; render.lisp - Rendering operations

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Writer and Output Functions
;;;; =========================================================================

(defun write-buffer ()
  "Create a buffer writer object for in-memory rendering.
Returns a writer handle that must be freed.

Example:
  (let ((writer (write-buffer)))
    (unwind-protect
        (progn
          (set-option \"render-output-format\" \"svg\")
          (render mol writer)
          (to-buffer writer))
      (indigo-free writer)))"
  (check-handle
   (cl-indigo.cffi::%indigo-write-buffer)
   "write-buffer"))

(defun to-buffer (writer)
  "Get the contents of WRITER as a string.
WRITER should be a buffer writer created with WRITE-BUFFER.
Returns the rendered output as a string.

Example:
  (let ((content (to-buffer writer)))
    (search \"<svg\" content))"
  (let ((result (cl-indigo.cffi::%indigo-to-string writer)))
    (when (and (stringp result) (string= result ""))
      nil)
    result))

;;;; =========================================================================
;;;; Molecule Rendering
;;;; =========================================================================

(defun render (object writer)
  "Render OBJECT to WRITER.
Returns T on success, signals INDIGO-ERROR on failure.

Example:
  (with-molecule (mol \"c1ccccc1\")
    (let ((writer (write-buffer)))
      (unwind-protect
          (progn
            (set-option \"render-output-format\" \"svg\")
            (render mol writer)
            (to-buffer writer))
        (indigo-free writer))))"
  (check-result
   (cl-indigo.cffi::%indigo-render object writer)
   "render"))

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
;;;; Grid Rendering
;;;; =========================================================================

(defun render-grid (array ref-atoms columns writer)
  "Render objects in ARRAY as a grid to WRITER.
REF-ATOMS is a list of reference atom indices (or NIL for none).
COLUMNS is the number of columns in the grid.

Example:
  (let ((arr (create-array))
        (writer (write-buffer)))
    (array-add arr mol1)
    (array-add arr mol2)
    (render-grid arr nil 2 writer)
    (to-buffer writer))"
  (if ref-atoms
      (cffi:with-foreign-object (params :int (length ref-atoms))
        (loop for i from 0 below (length ref-atoms)
              do (setf (cffi:mem-aref params :int i) (elt ref-atoms i)))
        (check-result (cl-indigo.cffi::%indigo-render-grid
                       array params columns writer)
                      "render-grid"))
      (check-result (cl-indigo.cffi::%indigo-render-grid
                     array (cffi:null-pointer) columns writer)
                    "render-grid")))

(defun render-grid-to-file (array ref-atoms columns filename)
  "Render objects in ARRAY as a grid to FILENAME.
REF-ATOMS is a list of reference atom indices (or NIL for none).
COLUMNS is the number of columns in the grid.

Example:
  (let ((arr (create-array)))
    (array-add arr mol1)
    (array-add arr mol2)
    (render-grid-to-file arr nil 2 \"grid.svg\"))"
  (if ref-atoms
      (cffi:with-foreign-object (params :int (length ref-atoms))
        (loop for i from 0 below (length ref-atoms)
              do (setf (cffi:mem-aref params :int i) (elt ref-atoms i)))
        (check-result (cl-indigo.cffi::%indigo-render-grid-to-file
                       array params columns (namestring filename))
                      "render-grid-to-file"))
      (check-result (cl-indigo.cffi::%indigo-render-grid-to-file
                     array (cffi:null-pointer) columns (namestring filename))
                    "render-grid-to-file")))

;;;; =========================================================================
;;;; Configuration
;;;; =========================================================================

(defun render-reset ()
  "Reset rendering options to defaults.
Returns T on success, signals INDIGO-ERROR on failure.

Example:
  (set-option \"render-output-format\" \"png\")
  (render-reset)  ; Back to defaults"
  (check-result
   (cl-indigo.cffi::%indigo-render-reset)
   "render-reset"))

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

(defun iterate-array (array)
  "Create an iterator over ARRAY.
Returns an iterator handle that must be freed.
Use WITH-ARRAY for automatic cleanup.

Example:
  (let ((arr (create-array)))
    (array-add arr mol1)
    (array-add arr mol2)
    (let ((iter (iterate-array arr)))
      (loop for item = (indigo-next iter)
            while item
            do ...)
      (indigo-free iter)))"
  (check-handle
   (cl-indigo.cffi::%indigo-iterate-array array)
   "iterate-array"))
