;;;; library.lisp - Indigo library loading

(in-package #:cl-indigo.cffi)

;;; Library definition
;;;
;;; The Indigo library can be found in different locations:
;;; 1. Local indigo-install/ directory (from ./install.sh)
;;; 2. System library path (LD_LIBRARY_PATH)
;;; 3. Standard system locations

(defvar *indigo-loaded* nil
  "T if the Indigo library has been loaded.")

(defun cl-indigo-root ()
  "Get the root directory of the cl-indigo system."
  (asdf:system-source-directory :cl-indigo))

(defun indigo-library-path ()
  "Get the path to the local Indigo library installation."
  (let ((root (cl-indigo-root)))
    (when root
      (merge-pathnames #p"indigo-install/lib/" root))))

(defun setup-library-path ()
  "Add local indigo-install/lib to CFFI's library search path."
  (let ((lib-path (indigo-library-path)))
    (when (and lib-path (probe-file lib-path))
      (pushnew lib-path cffi:*foreign-library-directories*
               :test #'equal))))

;;; Standard library definition - CFFI will search in *foreign-library-directories*
;;; and system paths (LD_LIBRARY_PATH, etc.)
(define-foreign-library libindigo
  (:unix (:or "libindigo.so" "libindigo.so.0d" "libindigo.so.1"))
  (:darwin (:or "libindigo.dylib" "libindigo.1.dylib"))
  (:windows (:or "indigo.dll" "indigo64.dll"))
  (t (:default "libindigo")))

(defun load-indigo-library ()
  "Load the Indigo shared library.
Returns T if successful, signals an error otherwise.

The library is searched for in:
1. ./indigo-install/lib/ (local installation via ./install.sh)
2. Directories in CFFI:*FOREIGN-LIBRARY-DIRECTORIES*
3. System library path (LD_LIBRARY_PATH on Unix)
4. Standard system locations (/usr/lib, etc.)"
  (unless *indigo-loaded*
    ;; First, set up the library path to include local install
    (setup-library-path)
    ;; Now try to load
    (handler-case
        (progn
          (use-foreign-library libindigo)
          (setf *indigo-loaded* t))
      (load-foreign-library-error (e)
        (let ((root (cl-indigo-root)))
          (error "Failed to load Indigo library: ~A~%~%~
                  To install Indigo, run:~%~
                    cd ~A~%~
                    ./install.sh linux-x86_64~%~%~
                  Or set LD_LIBRARY_PATH to include libindigo.so location."
                 e
                 (or root "."))))))
  *indigo-loaded*)
