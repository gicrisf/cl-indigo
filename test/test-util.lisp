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
