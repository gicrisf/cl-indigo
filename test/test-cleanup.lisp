;;;; test-cleanup.lisp - Resource cleanup tests

(in-package #:cl-indigo-tests)

(def-suite cleanup-tests
  :description "Tests for resource cleanup"
  :in :cl-indigo-tests)

(in-suite cleanup-tests)

;;;; =========================================================================
;;;; Basic Cleanup Tests
;;;; =========================================================================

(test molecule-cleanup
  "Test molecule cleanup."
  (with-reference-check
    (with-molecule (mol "CCO")
      (molecular-weight mol))))

(test nested-molecule-cleanup
  "Test nested molecule cleanup."
  (with-reference-check
    (with-molecule (mol1 "CCO")
      (with-molecule (mol2 "c1ccccc1")
        (+ (count-atoms mol1) (count-atoms mol2))))))

(test star-molecule-cleanup
  "Test with-molecule* cleanup."
  (with-reference-check
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1")
                     (mol3 "CC(=O)O"))
      (+ (count-atoms mol1)
         (count-atoms mol2)
         (count-atoms mol3)))))

;;;; =========================================================================
;;;; Error Cleanup Tests
;;;; =========================================================================

(test error-cleanup
  "Test cleanup on error."
  (with-reference-check
    (handler-case
        (with-molecule (mol "CCO")
          (error "Deliberate error"))
      (error () nil))))

(test nested-error-cleanup
  "Test nested cleanup on error."
  (with-reference-check
    (handler-case
        (with-molecule (mol1 "CCO")
          (with-molecule (mol2 "c1ccccc1")
            (error "Deliberate error")))
      (error () nil))))

;;;; =========================================================================
;;;; Iterator Cleanup Tests
;;;; =========================================================================

(test iterator-cleanup
  "Test iterator cleanup."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        (indigo-map #'atom-symbol atoms)))))

(test nested-iterator-cleanup
  "Test nested iterator cleanup."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        (with-bonds-iterator (bonds mol)
          (list (indigo-map #'atom-symbol atoms)
                (indigo-map #'bond-order bonds)))))))

;;;; =========================================================================
;;;; Stream Cleanup Tests
;;;; =========================================================================

(test stream-cleanup
  "Test stream cleanup."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (stream-collect (stream-map #'atom-symbol stream))))))

(test partial-stream-cleanup
  "Test cleanup when stream not fully consumed."
  (with-reference-check
    (with-molecule (mol "CCCCCC")  ; 6 atoms
      (with-atoms-stream (stream mol)
        ;; Only take first 2
        (stream-collect
         (stream-map #'atom-symbol
                     (stream-take 2 stream)))))))

;;;; =========================================================================
;;;; Mixed Resource Cleanup Tests
;;;; =========================================================================

(test mixed-cleanup
  "Test cleanup of mixed resources."
  (with-reference-check
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1"))
      (with-fingerprint* ((fp1 mol1 "sim")
                          (fp2 mol2 "sim"))
        (similarity fp1 fp2)))))
