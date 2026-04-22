;;;; packages.lisp - Test package definitions

(defpackage #:cl-indigo-tests
  (:use #:cl #:fiveam #:cl-indigo)
  (:documentation "Test suite for cl-indigo")
  (:export #:run-tests))

(in-package #:cl-indigo-tests)

(def-suite :cl-indigo-tests
  :description "All cl-indigo tests")

(defun run-tests ()
  "Run all cl-indigo tests."
  (run! :cl-indigo-tests))
