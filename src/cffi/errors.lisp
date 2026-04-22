;;;; errors.lisp - Error handling for cl-indigo

(in-package #:cl-indigo)

;;; Condition Definitions

(define-condition indigo-error (error)
  ((message :initarg :message
            :initform "Unknown Indigo error"
            :reader indigo-error-message
            :documentation "Error message from Indigo library"))
  (:documentation "Condition signaled when an Indigo operation fails.")
  (:report (lambda (condition stream)
             (format stream "Indigo error: ~A"
                     (indigo-error-message condition)))))

;;; Error Checking Utilities

(defun check-handle (handle &optional operation)
  "Check if HANDLE is valid, signal INDIGO-ERROR if not.
Returns HANDLE if valid."
  (cond
    ((cl-indigo.cffi::handle-valid-p handle)
     handle)
    ((cl-indigo.cffi::handle-error-p handle)
     (error 'indigo-error
            :message (format nil "~@[~A: ~]~A"
                            operation
                            (cl-indigo.cffi::%indigo-get-last-error))))
    (t
     (error 'indigo-error
            :message (format nil "~@[~A: ~]Invalid handle: ~A"
                            operation handle)))))

(defun check-result (result &optional operation)
  "Check if RESULT indicates success (non-negative), signal INDIGO-ERROR if not.
Returns RESULT if successful."
  (if (and (integerp result) (>= result 0))
      result
      (error 'indigo-error
             :message (format nil "~@[~A: ~]~A"
                             operation
                             (cl-indigo.cffi::%indigo-get-last-error)))))

(defmacro with-indigo-error-handling ((&optional operation) &body body)
  "Execute BODY and check result for Indigo errors.
Signals INDIGO-ERROR if the result indicates failure."
  `(check-handle (progn ,@body) ,operation))
