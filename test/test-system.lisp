;;;; test-system.lisp - Tests for system operations

(in-package #:cl-indigo-tests)

(def-suite system-tests
  :description "Tests for system operations"
  :in :cl-indigo-tests)

(in-suite system-tests)

;;;; =========================================================================
;;;; Version Tests
;;;; =========================================================================

(test indigo-version
  "Test getting Indigo version."
  (let ((version (indigo-version)))
    (is (stringp version))
    (is (> (length version) 0))))

;;;; =========================================================================
;;;; Session Management Tests
;;;; =========================================================================

(test session-management
  "Test session allocation, switching, and release."
  (let ((session-id-1 (alloc-session-id))
        (session-id-2 (alloc-session-id)))
    (is (integerp session-id-1))
    (is (integerp session-id-2))
    (is (> session-id-1 0))
    (is (> session-id-2 0))
    (is (not (= session-id-1 session-id-2)))

    ;; Switch to first session and verify by loading a molecule
    (is (eq (set-session-id session-id-1) t))
    (let ((handle-1 (load-molecule-from-string "CCO")))
      (is (integerp handle-1))

      ;; Switch to second session and verify it's different
      (is (eq (set-session-id session-id-2) t))
      (let ((handle-2 (load-molecule-from-string "c1ccccc1")))
        (is (integerp handle-2))

        ;; Switch back to first session and verify handle still works
        (is (eq (set-session-id session-id-1) t))
        (let ((smiles-1 (canonical-smiles handle-1)))
          (is (stringp smiles-1)))

        ;; Switch back to second session and verify its handle works
        (is (eq (set-session-id session-id-2) t))
        (let ((smiles-2 (canonical-smiles handle-2)))
          (is (stringp smiles-2)))

        ;; Clean up
        (indigo-free handle-2))

      ;; Switch back to first session to clean up
      (is (eq (set-session-id session-id-1) t))
      (indigo-free handle-1))

    ;; Release both sessions
    (is (eq (release-session-id session-id-1) t))
    (is (eq (release-session-id session-id-2) t))))

;;;; =========================================================================
;;;; Error Handling Tests
;;;; =========================================================================

(test error-handling
  "Test error handling functions."
  ;; First clear any existing errors by getting the last error
  (get-last-error)

  ;; Induce an error by trying to use an invalid handle
  (handler-case
      (canonical-smiles -1)  ; Invalid handle should cause an error
    (error () nil))  ; Ignore the error, we just want it logged

  ;; Now check that we can retrieve the error message
  (let ((err (get-last-error)))
    (is (stringp err))
    (is (> (length err) 0))))

;;;; =========================================================================
;;;; Reference Counting Tests
;;;; =========================================================================

(test reference-counting
  "Test reference counting functions."
  (let ((count-before (count-references)))
    (is (integerp count-before))
    (is (>= count-before 0))

    ;; Load a molecule and check reference count increased
    (let ((handle (load-molecule-from-string "CCO")))
      (let ((count-after (count-references)))
        (is (> count-after count-before))
        (indigo-free handle)))))

(test free-all-objects
  "Test freeing all objects in current session."
  ;; Load some molecules
  (let ((handle1 (load-molecule-from-string "CCO"))
        (handle2 (load-molecule-from-string "c1ccccc1")))
    (declare (ignore handle1 handle2))

    ;; Verify references exist
    (let ((count-before (count-references)))
      (is (> count-before 0))

      ;; Free all objects
      (let ((result (free-all-objects)))
        (is (integerp result))

        ;; Should be zero now
        (let ((count-after (count-references)))
          (is (= count-after 0)))))))

;;;; =========================================================================
;;;; Option Function Tests
;;;; =========================================================================

(test set-option-string
  "Test setting Indigo option with string value."
  (let ((result (set-option "render-output-format" "png")))
    (is (integerp result))))

(test set-option-integer
  "Test setting Indigo option with integer value."
  (let ((result (set-option-int "render-image-width" 400)))
    (is (integerp result))))

(test set-option-boolean
  "Test setting Indigo option with boolean value."
  (let ((result (set-option-bool "render-implicit-hydrogens-visible" 1)))
    (is (integerp result))))

(test set-option-floating-point
  "Test setting Indigo option with float value."
  (let ((result (set-option-float "render-bond-length" 20.0)))
    (is (integerp result))))

(test set-option-color-rgb
  "Test setting Indigo option with RGB color values."
  (let ((result (set-option-color "render-background-color" 1.0 1.0 1.0)))
    (is (integerp result))))

(test set-option-xy-coords
  "Test setting Indigo option with X,Y coordinate values."
  (let ((result (set-option-xy "render-image-size" 400 300)))
    (is (integerp result))))

(test option-error-handling
  "Test option functions with invalid option names."
  (let ((result1 (set-option "invalid-option-name" "value"))
        (result2 (set-option-int "another-invalid-option" 42)))
    (is (integerp result1))
    (is (integerp result2))))
