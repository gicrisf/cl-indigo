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

;;;; =========================================================================
;;;; Single-Level Nesting Tests
;;;; =========================================================================

(test nested-cleanup-single-molecule
  "Test reference counting with a single molecule."
  (let ((initial-refs (count-references)))
    ;; Outside scope: no resources allocated
    (is (= (count-references) initial-refs))

    (with-molecule (mol "CCO")
      ;; Inside scope: 1 molecule allocated
      (is (= (count-references) (+ initial-refs 1)))
      (is (integerp mol))
      (is (> mol 0)))

    ;; Outside scope: resource freed
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Two-Level Nesting Tests
;;;; =========================================================================

(test nested-cleanup-two-molecules-nested
  "Test reference counting with two nested molecules."
  (let ((initial-refs (count-references)))
    (is (= (count-references) initial-refs))

    (with-molecule (mol1 "CCO")
      ;; Level 1: 1 molecule allocated
      (is (= (count-references) (+ initial-refs 1)))

      (with-molecule (mol2 "c1ccccc1")
        ;; Level 2: 2 molecules allocated
        (is (= (count-references) (+ initial-refs 2)))
        (is (integerp mol1))
        (is (integerp mol2))
        (is (> mol1 0))
        (is (> mol2 0)))

      ;; Back to level 1: mol2 freed, mol1 still alive
      (is (= (count-references) (+ initial-refs 1))))

    ;; Outside scope: all resources freed
    (is (= (count-references) initial-refs))))

(test nested-cleanup-two-molecules-plural
  "Test reference counting with plural macro (sequential under the hood)."
  (let ((initial-refs (count-references)))
    (is (= (count-references) initial-refs))

    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1"))
      ;; Inside scope: 2 molecules allocated (created sequentially)
      (is (= (count-references) (+ initial-refs 2)))
      (is (integerp mol1))
      (is (integerp mol2))
      (is (> mol1 0))
      (is (> mol2 0)))

    ;; Outside scope: all resources freed
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Three-Level Nesting Tests
;;;; =========================================================================

(test nested-cleanup-three-molecules-nested
  "Test reference counting with three nested molecules."
  (let ((initial-refs (count-references)))
    (is (= (count-references) initial-refs))

    (with-molecule (mol1 "CCO")
      ;; Level 1: 1 molecule
      (is (= (count-references) (+ initial-refs 1)))

      (with-molecule (mol2 "c1ccccc1")
        ;; Level 2: 2 molecules
        (is (= (count-references) (+ initial-refs 2)))

        (with-molecule (mol3 "CCC")
          ;; Level 3: 3 molecules
          (is (= (count-references) (+ initial-refs 3)))
          (is (integerp mol1))
          (is (integerp mol2))
          (is (integerp mol3))
          (is (> mol1 0))
          (is (> mol2 0))
          (is (> mol3 0)))

        ;; Back to level 2: mol3 freed
        (is (= (count-references) (+ initial-refs 2))))

      ;; Back to level 1: mol2 and mol3 freed
      (is (= (count-references) (+ initial-refs 1))))

    ;; Outside scope: all freed
    (is (= (count-references) initial-refs))))

(test nested-cleanup-three-molecules-plural
  "Test reference counting with three molecules using plural macro."
  (let ((initial-refs (count-references)))
    (is (= (count-references) initial-refs))

    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1")
                     (mol3 "CCC"))
      ;; Inside scope: 3 molecules allocated
      (is (= (count-references) (+ initial-refs 3)))
      (is (integerp mol1))
      (is (integerp mol2))
      (is (integerp mol3)))

    ;; Outside scope: all freed
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Error Handling with Partial Cleanup Tests
;;;; =========================================================================

(test nested-cleanup-error-in-first-molecule
  "Test cleanup when first molecule creation fails."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule (mol1 "INVALID_SMILES")
        (declare (ignore mol1))
        nil))

    ;; No resources leaked (mol1 never created)
    (is (= (count-references) initial-refs))))

(test nested-cleanup-error-in-second-molecule
  "Test cleanup when second molecule creation fails (first should still cleanup)."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule (mol1 "CCO")
        (with-molecule (mol2 "INVALID_SMILES")
          (declare (ignore mol1 mol2))
          nil)))

    ;; All resources cleaned up (mol1 was created then freed via unwind-protect)
    (is (= (count-references) initial-refs))))

(test nested-cleanup-error-in-third-molecule
  "Test cleanup when third molecule creation fails (first two should cleanup)."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule (mol1 "CCO")
        (with-molecule (mol2 "c1ccccc1")
          (with-molecule (mol3 "INVALID_SMILES")
            (declare (ignore mol1 mol2 mol3))
            nil))))

    ;; All resources cleaned up
    (is (= (count-references) initial-refs))))

(test nested-cleanup-error-in-plural-second
  "Test cleanup with plural macro when second molecule fails."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule* ((mol1 "CCO")
                       (mol2 "INVALID_SMILES")
                       (mol3 "CCC"))
        (declare (ignore mol1 mol2 mol3))
        nil))

    ;; All resources cleaned up (mol1 was created then freed)
    (is (= (count-references) initial-refs))))

(test nested-cleanup-error-in-plural-third
  "Test cleanup with plural macro when third molecule fails."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule* ((mol1 "CCO")
                       (mol2 "c1ccccc1")
                       (mol3 "INVALID_SMILES"))
        (declare (ignore mol1 mol2 mol3))
        nil))

    ;; All resources cleaned up (mol1 and mol2 were created then freed)
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Error in Body Tests
;;;; =========================================================================

(test nested-cleanup-error-in-body-nested
  "Test cleanup when error occurs in body (after molecules created)."
  (let ((initial-refs (count-references)))
    (handler-case
        (with-molecule (mol1 "CCO")
          (with-molecule (mol2 "c1ccccc1")
            (declare (ignore mol1 mol2))
            (error "Test error in body")))
      (error () nil))

    ;; All resources cleaned up
    (is (= (count-references) initial-refs))))

(test nested-cleanup-error-in-body-plural
  "Test cleanup when error occurs in body with plural macro."
  (let ((initial-refs (count-references)))
    (handler-case
        (with-molecule* ((mol1 "CCO")
                         (mol2 "c1ccccc1")
                         (mol3 "CCC"))
          (declare (ignore mol1 mol2 mol3))
          (error "Test error in body"))
      (error () nil))

    ;; All resources cleaned up
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Deep Nesting (Stress Test)
;;;; =========================================================================

(test nested-cleanup-five-levels
  "Test reference counting with five levels of nesting (stress test)."
  (let ((initial-refs (count-references)))
    (with-molecule (mol1 "C")
      (is (= (count-references) (+ initial-refs 1)))

      (with-molecule (mol2 "CC")
        (is (= (count-references) (+ initial-refs 2)))

        (with-molecule (mol3 "CCC")
          (is (= (count-references) (+ initial-refs 3)))

          (with-molecule (mol4 "CCCC")
            (is (= (count-references) (+ initial-refs 4)))

            (with-molecule (mol5 "CCCCC")
              (is (= (count-references) (+ initial-refs 5)))
              ;; All 5 molecules should be alive
              (is (integerp mol1))
              (is (integerp mol2))
              (is (integerp mol3))
              (is (integerp mol4))
              (is (integerp mol5)))

            ;; mol5 freed
            (is (= (count-references) (+ initial-refs 4))))

          ;; mol4 and mol5 freed
          (is (= (count-references) (+ initial-refs 3))))

        ;; mol3, mol4, mol5 freed
        (is (= (count-references) (+ initial-refs 2))))

      ;; mol2-mol5 freed
      (is (= (count-references) (+ initial-refs 1))))

    ;; All freed
    (is (= (count-references) initial-refs))))

(test nested-cleanup-five-molecules-plural
  "Test reference counting with five molecules using plural macro."
  (let ((initial-refs (count-references)))
    (with-molecule* ((mol1 "C")
                     (mol2 "CC")
                     (mol3 "CCC")
                     (mol4 "CCCC")
                     (mol5 "CCCCC"))
      ;; All 5 allocated
      (is (= (count-references) (+ initial-refs 5)))
      (is (integerp mol1))
      (is (integerp mol2))
      (is (integerp mol3))
      (is (integerp mol4))
      (is (integerp mol5)))

    ;; All freed
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Reaction and Mixed Resource Tests
;;;; =========================================================================

(test nested-cleanup-reaction-and-iterators
  "Test reference counting with reactions and iterators."
  (let ((initial-refs (count-references)))
    (with-reaction (rxn "CCO.CC>>CCOC")
      ;; 1 reaction
      (is (= (count-references) (+ initial-refs 1)))

      (with-reactants-iterator (reactants rxn)
        ;; Reaction + iterator
        (is (>= (count-references) (+ initial-refs 1)))

        (with-products-iterator (products rxn)
          ;; Reaction + 2 iterators
          (is (>= (count-references) (+ initial-refs 1)))
          (is-true reactants)
          (is-true products))

        ;; Products iterator freed
        (is (>= (count-references) (+ initial-refs 1))))

      ;; Reactants iterator freed
      (is (= (count-references) (+ initial-refs 1))))

    ;; All freed
    (is (= (count-references) initial-refs))))

(test nested-cleanup-molecules-and-fingerprints
  "Test reference counting with molecules and fingerprints."
  (let ((initial-refs (count-references)))
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1"))
      ;; 2 molecules
      (is (= (count-references) (+ initial-refs 2)))

      (with-fingerprint* ((fp1 mol1 "sim")
                          (fp2 mol2 "sim"))
        ;; 2 molecules + 2 fingerprints = 4
        (is (= (count-references) (+ initial-refs 4)))
        (let ((sim (similarity fp1 fp2)))
          (is (floatp sim))))

      ;; Fingerprints freed, molecules still alive
      (is (= (count-references) (+ initial-refs 2))))

    ;; All freed
    (is (= (count-references) initial-refs))))
