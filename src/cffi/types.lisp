;;;; types.lisp - CFFI type definitions

(in-package #:cl-indigo.cffi)

;;; Indigo Handle Type
;;;
;;; Indigo uses integer handles to reference objects:
;;; - Positive integer: valid handle
;;; - Zero: iterator exhausted / false
;;; - Negative (-1): error occurred

(deftype indigo-handle ()
  "Type for Indigo object handles."
  '(signed-byte 32))

;;; Handle validation functions

(declaim (inline handle-valid-p handle-error-p handle-end-p))

(defun handle-valid-p (handle)
  "Return T if HANDLE is a valid Indigo handle (positive integer)."
  (and (integerp handle) (> handle 0)))

(defun handle-error-p (handle)
  "Return T if HANDLE indicates an error (-1)."
  (and (integerp handle) (= handle -1)))

(defun handle-end-p (handle)
  "Return T if HANDLE indicates iterator end (0 or NIL)."
  (or (null handle)
      (and (integerp handle) (zerop handle))))

;;; Session ID type
;;; Indigo uses 64-bit unsigned integers for session IDs

(deftype session-id ()
  "Type for Indigo session identifiers."
  '(unsigned-byte 64))
