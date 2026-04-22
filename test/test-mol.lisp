;;;; test-mol.lisp - Molecule tests

(in-package #:cl-indigo-tests)

(def-suite mol-tests
  :description "Tests for molecular operations"
  :in :cl-indigo-tests)

(in-suite mol-tests)

;;;; =========================================================================
;;;; Loading Tests
;;;; =========================================================================

(test molecule-loading
  "Test loading molecules from SMILES strings."
  (with-molecule (mol "CCO")
    (is (integerp mol))
    (is (> mol 0))))

(test molecule-loading-error
  "Test that invalid SMILES signals an error."
  (signals indigo-error
    (load-molecule-from-string "INVALID_NOT_A_SMILES")))

(test molecule-cleanup
  "Test that with-molecule properly cleans up."
  (with-reference-check
    (with-molecule (mol "CCO")
      (is (> mol 0)))))

;;;; =========================================================================
;;;; Property Tests
;;;; =========================================================================

(test molecular-weight
  "Test molecular weight calculation."
  (with-molecule (mol "CCO")  ; Ethanol: C2H6O = 46.069
    (let ((weight (molecular-weight mol)))
      (is (floatp weight))
      (is (float-equal weight 46.069 0.01)))))

(test canonical-smiles
  "Test canonical SMILES generation."
  (with-molecule (mol "OCC")  ; Ethanol written backwards
    (let ((smiles (canonical-smiles mol)))
      (is (stringp smiles))
      ;; Canonical form should be consistent
      (is (or (string= smiles "CCO")
              (string= smiles "OCC"))))))

(test count-atoms
  "Test atom counting."
  (with-molecule (mol "CCO")
    (is (= 3 (count-atoms mol)))))

(test count-bonds
  "Test bond counting."
  (with-molecule (mol "CCO")
    (is (= 2 (count-bonds mol)))))

(test gross-formula
  "Test gross formula generation."
  (with-molecule (mol "CCO")
    (let ((formula (gross-formula mol)))
      (is (stringp formula))
      (is (string= formula "C2 H6 O")))))

;;;; =========================================================================
;;;; Star Macro Tests
;;;; =========================================================================

(test with-molecule-star
  "Test with-molecule* for multiple molecules."
  (with-reference-check
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1"))
      (is (integerp mol1))
      (is (integerp mol2))
      (is (not (= mol1 mol2)))
      (is (float-equal (molecular-weight mol1) 46.069 0.01))
      (is (float-equal (molecular-weight mol2) 78.114 0.01)))))

;;;; =========================================================================
;;;; Manipulation Tests
;;;; =========================================================================

(test layout
  "Test 2D layout generation."
  (with-molecule (mol "CCO")
    (is (not (has-coordinates mol)))
    (layout mol)
    (is (has-coordinates mol))))

(test aromatize
  "Test aromatization."
  (with-molecule (mol "C1=CC=CC=C1")  ; Kekulé benzene
    (aromatize mol)
    (let ((smiles (canonical-smiles mol)))
      ;; Should be aromatic notation
      (is (search "c" smiles)))))
