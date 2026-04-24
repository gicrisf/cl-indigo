;;;; test-util.lisp - Test utilities

(in-package #:cl-indigo-tests)

;;; Test data directory
(defparameter *test-data-dir*
  (merge-pathnames #p"test/data/"
                   (asdf:system-source-directory :cl-indigo))
  "Directory containing test data files.")

(defun test-file (name)
  "Get path to test file NAME."
  (merge-pathnames name *test-data-dir*))

;;; Approximate float comparison
(defun float-equal (a b &optional (tolerance 0.01))
  "Check if floats A and B are approximately equal within TOLERANCE."
  (< (abs (- a b)) tolerance))

;;; Reference counting helper
(defmacro with-reference-check (&body body)
  "Execute BODY and verify reference count returns to initial value."
  (let ((initial (gensym "INITIAL")))
    `(let ((,initial (count-references)))
       (prog1 (progn ,@body)
         (is (= ,initial (count-references))
             "Reference count should return to ~A, but is ~A"
             ,initial (count-references))))))

;;; Temporary file helper
(defmacro with-temp-file ((var &optional (prefix "cl-indigo-test") (suffix ".tmp")) &body body)
  "Execute BODY with temporary file pathname bound to VAR.
File is deleted after BODY completes (even on error)."
  (let ((path (gensym "PATH")))
    `(let* ((,path (merge-pathnames
                    (format nil "~A-~A~A"
                            ,prefix
                            (get-universal-time)
                            ,suffix)
                    (uiop:temporary-directory)))
            (,var ,path))
       (unwind-protect
           (progn ,@body)
         (when (probe-file ,path)
           (delete-file ,path))))))

;;; File content helper
(defun read-file-contents (pathname)
  "Read entire file contents as a string."
  (with-open-file (stream pathname :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun write-file-contents (pathname contents)
  "Write CONTENTS string to file at PATHNAME."
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-string contents stream)))
