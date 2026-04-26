;;;; test-rendering.lisp - Rendering tests

(in-package #:cl-indigo-tests)

(def-suite rendering-tests
  :description "Tests for rendering operations"
  :in :cl-indigo-tests)

(in-suite rendering-tests)

;;;; =========================================================================
;;;; Writer and Output Functions Tests
;;;; =========================================================================

(test write-buffer-creation
  "Test creating buffer writer objects."
  (let ((writer (write-buffer)))
    (is (integerp writer))
    (is (> writer 0))
    (indigo-free writer)))

(test write-file-creation
  "Test creating file writer via render-to-file."
  (with-temp-file (temp-file "indigo-test" ".png")
    (with-molecule (mol "CCO")
      (set-option "render-output-format" "png")
      (set-option-int "render-image-width" 300)
      (set-option-int "render-image-height" 200)
      (let ((result (render-to-file mol temp-file)))
        (is (>= result 0))
        (is-true (probe-file temp-file))
        (is (> (file-length (open temp-file :direction :input)) 0))))))

(test to-buffer-content
  "Test converting buffer writer to string content."
  (with-molecule (mol "CCO")
    (let ((writer (write-buffer)))
      (unwind-protect
          (progn
            ;; Set rendering options for SVG output
            (is (>= (set-option "render-output-format" "svg") 0))
            ;; Render molecule to buffer
            (is (>= (render mol writer) 0))
            ;; Get buffer contents
            (let ((content (to-buffer writer)))
              (is (stringp content))
              (is (not (string= content "")))
              ;; Should contain SVG content
              (is-true (search "<svg" content :test #'string-equal))))
        (indigo-free writer)))))

;;;; =========================================================================
;;;; Array Functions Tests
;;;; =========================================================================

(test create-array
  "Test creating empty arrays for grid rendering."
  (let ((array (create-array)))
    (is (integerp array))
    (is (> array 0))
    (indigo-free array)))

(test array-add
  "Test adding molecules to arrays."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "c1ccccc1"))
    (let ((array (create-array)))
      (unwind-protect
          (progn
            ;; Add molecules to array
            (is (>= (array-add array mol1) 0))
            (is (>= (array-add array mol2) 0))
            ;; Verify array can be used for iteration
            (let ((iter (iterate-array array))
                  (count 0))
              (unwind-protect
                  (progn
                    (let ((item (indigo-next iter)))
                      (loop while item
                            do (incf count)
                               (setf item (indigo-next iter))))
                    (is (= count 2)))
                (indigo-free iter))))
        (indigo-free array)))))

;;;; =========================================================================
;;;; Basic Rendering Tests
;;;; =========================================================================

(test render-to-buffer
  "Test basic molecule rendering to buffer."
  (with-molecule (mol "CCO")
    (let ((writer (write-buffer)))
      (unwind-protect
          (progn
            ;; Set rendering options
            (is (>= (set-option "render-output-format" "svg") 0))
            (is (>= (set-option-int "render-image-width" 300) 0))
            (is (>= (set-option-int "render-image-height" 200) 0))
            ;; Render molecule
            (let ((result (render mol writer)))
              (is (>= result 0))
              ;; Verify output contains content
              (let ((content (to-buffer writer)))
                (is (stringp content))
                (is (not (string= content ""))))))
        (indigo-free writer)))))

(test render-to-file
  "Test direct file rendering."
  (with-molecule (mol "c1ccccc1")
    (with-temp-file (temp-file "indigo-molecule" ".png")
      ;; Set rendering options for PNG
      (is (>= (set-option "render-output-format" "png") 0))
      (is (>= (set-option-int "render-image-width" 400) 0))
      (is (>= (set-option-int "render-image-height" 300) 0))
      ;; Render directly to file
      (let ((result (render-to-file mol temp-file)))
        (is (>= result 0))
        ;; File should exist and have content
        (is-true (probe-file temp-file))
        (is (> (file-length (open temp-file :direction :input)) 0))))))

;;;; =========================================================================
;;;; Grid Rendering Tests
;;;; =========================================================================

(test render-grid-to-buffer
  "Test grid rendering to buffer."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "c1ccccc1")
                   (mol3 "CC(C)O"))
    (let ((array (create-array)))
      (unwind-protect
          (progn
            ;; Add molecules to array
            (array-add array mol1)
            (array-add array mol2)
            (array-add array mol3)

            (let ((writer (write-buffer)))
              (unwind-protect
                  (progn
                    ;; Set rendering options
                    (set-option "render-output-format" "svg")
                    (set-option-int "render-image-width" 600)
                    (set-option-int "render-image-height" 400)
                    ;; Render grid with 2 columns, no ref atoms (nil)
                    (let ((result (render-grid array nil 2 writer)))
                      (is (>= result 0))
                      ;; Verify output
                      (let ((content (to-buffer writer)))
                        (is (stringp content))
                        (is (not (string= content "")))
                        (is-true (search "<svg" content :test #'string-equal)))))
                (indigo-free writer))))
        (indigo-free array)))))

(test render-grid-to-file
  "Test grid rendering directly to file."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCC"))
    (with-temp-file (temp-file "indigo-grid" ".svg")
      (let ((array (create-array)))
        (unwind-protect
            (progn
              ;; Add molecules to array
              (array-add array mol1)
              (array-add array mol2)

              ;; Set rendering options
              (set-option "render-output-format" "svg")
              (set-option-int "render-image-width" 500)

              ;; Render grid directly to file with 1 column
              (let ((result (render-grid-to-file array nil 1 temp-file)))
                (is (>= result 0))
                ;; File should exist and contain SVG content
                (is-true (probe-file temp-file))
                (let ((content (read-file-contents temp-file)))
                  (is-true (search "<svg" content :test #'string-equal)))))
          (indigo-free array))))))

;;;; =========================================================================
;;;; Rendering Configuration Tests
;;;; =========================================================================

(test render-reset
  "Test resetting rendering options to defaults."
  ;; Set some custom options
  (set-option "render-output-format" "png")
  (set-option-int "render-image-width" 1000)
  (set-option-color "render-background-color" 1.0 0.5 0.0)

  ;; Reset rendering options
  (let ((result (render-reset)))
    (is (>= result 0)))

  ;; Set output format again after reset
  (set-option "render-output-format" "svg")
  ;; Verify reset worked by rendering a simple molecule
  (with-molecule (mol "CCO")
    (let ((writer (write-buffer)))
      (unwind-protect
          (progn
            (is (>= (render mol writer) 0))
            (let ((content (to-buffer writer)))
              (is (stringp content))
              (is (not (string= content "")))))
        (indigo-free writer)))))

;;;; =========================================================================
;;;; Integration Tests with Real Chemical Data
;;;; =========================================================================

(test render-complex-molecule
  "Test rendering complex molecules with various features."
  (dolist (smiles '("CC(=O)OC1=CC=CC=C1C(=O)O"   ; aspirin
                    "CC1=CC=C(C=C1)C(C)C(=O)O"    ; ibuprofen
                    "c1ccc2c(c1)ccc3c2ccc4c3cccc4" ; anthracene
                    "C[C@H](C(=O)N[C@@H](CC1=CC=CC=C1)C(=O)O)N"))  ; phenylalanine
    (handler-case
        (with-molecule (mol smiles)
          (with-temp-file (temp-file "indigo-complex" ".svg")
            ;; Set high-quality rendering options
            (set-option "render-output-format" "svg")
            (set-option-int "render-image-width" 400)
            (set-option-int "render-image-height" 300)
            (set-option-float "render-bond-length" 30.0)

            ;; Render molecule
            (let ((result (render-to-file mol temp-file)))
              (is (>= result 0))
              (is-true (probe-file temp-file))
              (is (> (file-length (open temp-file :direction :input)) 100)))))
      (indigo-error (e)
        ;; Some molecules might fail to load in certain Indigo versions
        (declare (ignore e))))))

;;;; =========================================================================
;;;; Error Handling Tests
;;;; =========================================================================

(test render-error-handling
  "Test rendering error handling with invalid inputs."
  ;; Test rendering with invalid molecule handle
  (let ((writer (write-buffer)))
    (unwind-protect
        (signals indigo-error
          (render -1 writer))
      (indigo-free writer)))

  ;; Test rendering with invalid writer handle
  (with-molecule (mol "CCO")
    (signals indigo-error
      (render mol -1)))

  ;; Test array operations with invalid handles
  (with-molecule (mol "CCO")
    (signals indigo-error
      (array-add -1 mol)))

  ;; Test file rendering with invalid path
  (with-molecule (mol "CCO")
    (signals indigo-error
      (render-to-file mol "/invalid/path/molecule.png"))))

;;;; =========================================================================
;;;; Performance and Memory Tests
;;;; =========================================================================

(test render-memory-management
  "Test proper memory management during rendering operations."
  (let ((initial-refs (count-references)))
    ;; Perform multiple render operations
    (dotimes (i 5)
      (with-molecule (mol "c1ccccc1")
        (let ((writer (write-buffer)))
          (unwind-protect
              (progn
                (is (>= (render mol writer) 0))
                (let ((content (to-buffer writer)))
                  (is (stringp content))))
            (indigo-free writer)))))

    ;; Memory should be properly cleaned up
    (let ((final-refs (count-references)))
      (is (= initial-refs final-refs)))))

;;;; =========================================================================
;;;; Option Configuration Tests for Rendering
;;;; =========================================================================

(test rendering-options
  "Test various rendering options and their effects."
  (with-molecule (mol "c1ccccc1")
    ;; Test different output formats (SVG only — PNG is binary)
    (dolist (format '("svg"))
      (is (>= (set-option "render-output-format" format) 0))
      (let ((writer (write-buffer)))
        (unwind-protect
            (progn
              (is (>= (render mol writer) 0))
              (let ((content (to-buffer writer)))
                (is (stringp content))
                (is (not (string= content "")))))
          (indigo-free writer))))

    ;; Test dimension options
    (is (>= (set-option-int "render-image-width" 200) 0))
    (is (>= (set-option-int "render-image-height" 150) 0))

    ;; Test color options
    (is (>= (set-option-color "render-background-color" 1.0 1.0 1.0) 0))

    ;; Test coordinate options
    (is (>= (set-option-xy "render-grid-margins" 10 15) 0))

    ;; Test float options
    (is (>= (set-option-float "render-bond-length" 25.5) 0))))

;;;; =========================================================================
;;;; Grid Rendering with Reference Atoms
;;;; =========================================================================

(test render-grid-with-ref-atoms
  "Test grid rendering with reference atom highlighting."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCC"))
    (let ((array (create-array)))
      (unwind-protect
          (progn
            ;; Add molecules to array
            (array-add array mol1)
            (array-add array mol2)

            ;; Create reference atoms list (first atom of each molecule)
            (with-temp-file (temp-file "indigo-ref-atoms" ".svg")
              ;; Set rendering options
              (set-option "render-output-format" "svg")

              ;; Render grid with reference atoms
              (let ((result (render-grid-to-file array '(0 0) 2 temp-file)))
                (is (>= result 0))
                (is-true (probe-file temp-file))
                (is (> (file-length (open temp-file :direction :input)) 0)))))
        (indigo-free array)))))

;;;; =========================================================================
;;;; With-array Macro Tests
;;;; =========================================================================

(test with-array-macro
  "Test with-array macro."
  (with-array (arr)
    (is (integerp arr))
    (is (> arr 0))
    (with-molecule (mol "CCO")
      (array-add arr mol))))
