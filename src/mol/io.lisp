;;;; io.lisp - Molecule I/O operations

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Molecule Loading from Strings
;;;; =========================================================================

(defun load-molecule-from-string (string)
  "Load molecule from STRING (SMILES, MOL, etc.).
Returns handle on success, signals INDIGO-ERROR on failure.

Example:
  (load-molecule-from-string \"CCO\")  ; Ethanol"
  (check-handle
   (cl-indigo.cffi::%indigo-load-molecule-from-string string)
   "load-molecule-from-string"))

(defun load-query-molecule-from-string (string)
  "Load query molecule from STRING.
Query molecules can contain wildcards and query features.
Returns handle on success, signals INDIGO-ERROR on failure."
  (check-handle
   (cl-indigo.cffi::%indigo-load-query-molecule-from-string string)
   "load-query-molecule-from-string"))

(defun load-smarts-from-string (string)
  "Load SMARTS pattern from STRING.
Returns handle on success, signals INDIGO-ERROR on failure.

Example:
  (load-smarts-from-string \"[#6]=[#8]\")  ; Carbonyl pattern"
  (check-handle
   (cl-indigo.cffi::%indigo-load-smarts-from-string string)
   "load-smarts-from-string"))

(defun load-reaction-from-string (string)
  "Load reaction from STRING (reaction SMILES).
Returns handle on success, signals INDIGO-ERROR on failure.

Example:
  (load-reaction-from-string \"CC>>C.C\")  ; Ethane to two methanes"
  (check-handle
   (cl-indigo.cffi::%indigo-load-reaction-from-string string)
   "load-reaction-from-string"))

;;;; =========================================================================
;;;; Molecule Loading from Files
;;;; =========================================================================

(defun load-molecule-from-file (filename)
  "Load molecule from FILENAME.
Supports MOL, SDF, and other file formats.
Returns handle on success, signals INDIGO-ERROR on failure.

Example:
  (load-molecule-from-file \"molecule.mol\")"
  (let ((path (namestring (truename filename))))
    (unless (probe-file path)
      (error 'indigo-error
             :message (format nil "File does not exist: ~A" filename)))
    (check-handle
     (cl-indigo.cffi::%indigo-load-molecule-from-file path)
     "load-molecule-from-file")))

(defun load-query-molecule-from-file (filename)
  "Load query molecule from FILENAME.
Returns handle on success, signals INDIGO-ERROR on failure."
  (let ((path (namestring (truename filename))))
    (unless (probe-file path)
      (error 'indigo-error
             :message (format nil "File does not exist: ~A" filename)))
    (check-handle
     (cl-indigo.cffi::%indigo-load-query-molecule-from-file path)
     "load-query-molecule-from-file")))

(defun load-smarts-from-file (filename)
  "Load SMARTS pattern from FILENAME.
Returns handle on success, signals INDIGO-ERROR on failure."
  (let ((path (namestring (truename filename))))
    (unless (probe-file path)
      (error 'indigo-error
             :message (format nil "File does not exist: ~A" filename)))
    (check-handle
     (cl-indigo.cffi::%indigo-load-smarts-from-file path)
     "load-smarts-from-file")))

(defun load-reaction-from-file (filename)
  "Load reaction from FILENAME.
Returns handle on success, signals INDIGO-ERROR on failure."
  (let ((path (namestring (truename filename))))
    (unless (probe-file path)
      (error 'indigo-error
             :message (format nil "File does not exist: ~A" filename)))
    (check-handle
     (cl-indigo.cffi::%indigo-load-reaction-from-file path)
     "load-reaction-from-file")))

;;;; =========================================================================
;;;; Low-Level Handle Operations
;;;; =========================================================================

(defun indigo-free (handle)
  "Free an Indigo object HANDLE.
Usually you should use with-* macros instead of manual cleanup."
  (when handle
    (cl-indigo.cffi::%indigo-free handle)))

(defun indigo-clone (handle)
  "Clone an Indigo object HANDLE.
Returns a new handle that must be freed separately."
  (check-handle
   (cl-indigo.cffi::%indigo-clone handle)
   "indigo-clone"))
