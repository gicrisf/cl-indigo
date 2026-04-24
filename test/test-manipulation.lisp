;;;; test-manipulation.lisp - Tests for structure manipulation functions

(in-package #:cl-indigo-tests)

(def-suite manipulation-tests
  :description "Tests for structure manipulation functions"
  :in :cl-indigo-tests)

(in-suite manipulation-tests)

;;;; =========================================================================
;;;; Aromatization Tests
;;;; =========================================================================

(test aromatize-api
  "Test aromatize function with new idiomatic API."
  ;; Test 1: Kekule benzene - should return :changed
  (with-molecule (mol1 "C1=CC=CC=C1")
    (is (eq (aromatize mol1) :changed)))

  ;; Test 2: Already aromatic benzene - should return :unchanged
  (with-molecule (mol2 "c1ccccc1")
    (is (eq (aromatize mol2) :unchanged)))

  ;; Test 3: Pyridine (already aromatic) - should return :unchanged
  (with-molecule (mol3 "c1cccnc1")
    (is (eq (aromatize mol3) :unchanged)))

  ;; Test 4: Propane (aliphatic, no aromatic rings) - should return :unchanged
  (with-molecule (mol4 "CCC")
    (is (eq (aromatize mol4) :unchanged))))

(test aromatize-benzene
  "Test aromatizing benzene from Kekule form."
  (with-molecule (mol "C1=CC=CC=C1")  ; Kekule benzene
    ;; Should return :changed (Kekule converted to aromatic)
    (let ((status (aromatize mol)))
      (is (eq status :changed)))))

(test aromatize-aliphatic
  "Test aromatizing aliphatic molecule (no aromatic rings)."
  (with-molecule (mol "CCC")  ; Propane
    ;; Should return :unchanged (no aromatic rings)
    (let ((status (aromatize mol)))
      (is (eq status :unchanged)))))

(test aromatize-heterocycle
  "Test aromatizing heterocyclic aromatic compound."
  (with-molecule (mol "c1cccnc1")  ; Pyridine (already aromatic)
    ;; Should return :unchanged (already aromatic)
    (let ((status (aromatize mol)))
      (is (eq status :unchanged)))))

;;;; =========================================================================
;;;; Layout (2D Coordinate Calculation) Tests
;;;; =========================================================================

(test layout-api
  "Test layout function with new idiomatic API."
  ;; Test 1: Molecule without coordinates
  (with-molecule (mol1 "CCO")
    (is-false (has-coordinates mol1))
    (is-true (layout mol1))
    (is-true (has-coordinates mol1)))

  ;; Test 2: Call layout again (should succeed - recalculates coords)
  (with-molecule (mol2 "CCO")
    (is-true (layout mol2))  ; First layout
    (is-true (has-coordinates mol2))
    (is-true (layout mol2))  ; Second layout should also succeed
    (is-true (has-coordinates mol2)))

  ;; Test 3: Benzene
  (with-molecule (mol3 "c1ccccc1")
    (is-true (layout mol3)))

  ;; Test 4: Complex molecule
  (with-molecule (mol4 "CN1C=NC2=C1C(=O)N(C(=O)N2C)C")
    (is-true (layout mol4))))

(test layout-simple
  "Test calculating 2D coordinates for simple molecule."
  (with-molecule (mol "CCO")  ; Ethanol
    ;; Calculate layout (returns t on success)
    (is-true (layout mol))
    ;; After layout, should have coordinates
    (is-true (has-coordinates mol))))

(test layout-benzene
  "Test calculating 2D coordinates for benzene."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    ;; Calculate layout (returns t on success)
    (is-true (layout mol))
    ;; After layout, should have coordinates
    (is-true (has-coordinates mol))
    ;; Should not have Z coordinates (2D only)
    (is-false (has-z-coord mol))))

(test layout-complex
  "Test calculating 2D coordinates for complex molecule."
  (with-molecule (mol "CN1C=NC2=C1C(=O)N(C(=O)N2C)C")  ; Caffeine
    ;; Calculate layout (returns t on success)
    (is-true (layout mol))
    ;; After layout, should have coordinates
    (is-true (has-coordinates mol))))

;;;; =========================================================================
;;;; Hydrogen Folding Tests
;;;; =========================================================================

(test fold-unfold-hydrogens-api
  "Test fold/unfold hydrogens with new idiomatic API."
  (with-molecule (mol "CCO")  ; Ethanol
    (let ((initial-count (count-atoms mol)))
      (is (= initial-count 3)))

    ;; Unfold should succeed and return t
    (is-true (unfold-hydrogens mol))
    (let ((unfolded-count (count-atoms mol)))
      (is (> unfolded-count 3)))

    ;; Fold should succeed and return t
    (is-true (fold-hydrogens mol))
    (let ((folded-count (count-atoms mol)))
      (is (= folded-count 3)))))

(test fold-hydrogens-ethanol
  "Test folding (removing) explicit hydrogen atoms from ethanol."
  (with-molecule (mol "CCO")  ; Ethanol
    ;; First unfold to add explicit hydrogens
    (is-true (unfold-hydrogens mol))
    ;; Count atoms with explicit H
    (let ((atom-count-with-h (count-atoms mol)))
      (is (> atom-count-with-h 3)))  ; More than 3 heavy atoms
    ;; Fold hydrogens (remove explicit H)
    (is-true (fold-hydrogens mol))
    ;; Count atoms after folding
    (let ((atom-count-folded (count-atoms mol)))
      (is (= atom-count-folded 3)))))  ; Only C, C, O

(test fold-hydrogens-benzene
  "Test folding hydrogen atoms from benzene."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    ;; Unfold first
    (is-true (unfold-hydrogens mol))
    (let ((atom-count-unfolded (count-atoms mol)))
      (is (= atom-count-unfolded 12)))  ; 6 C + 6 H
    ;; Fold hydrogens
    (is-true (fold-hydrogens mol))
    (let ((atom-count-folded (count-atoms mol)))
      (is (= atom-count-folded 6)))))  ; Only 6 C

;;;; =========================================================================
;;;; Hydrogen Unfolding Tests
;;;; =========================================================================

(test unfold-hydrogens-ethanol
  "Test unfolding (adding) explicit hydrogen atoms to ethanol."
  (with-molecule (mol "CCO")  ; Ethanol
    ;; Count atoms before unfolding
    (let ((atom-count-before (count-atoms mol)))
      (is (= atom-count-before 3)))  ; C, C, O
    ;; Unfold hydrogens
    (is-true (unfold-hydrogens mol))
    ;; Count atoms after unfolding
    (let ((atom-count-after (count-atoms mol)))
      (is (> atom-count-after 3)))))  ; C, C, O + H atoms

(test unfold-hydrogens-benzene
  "Test unfolding hydrogen atoms to benzene."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    ;; Count atoms before unfolding
    (let ((atom-count-before (count-atoms mol)))
      (is (= atom-count-before 6)))  ; 6 C atoms
    ;; Unfold hydrogens
    (is-true (unfold-hydrogens mol))
    ;; Count atoms after unfolding
    (let ((atom-count-after (count-atoms mol)))
      (is (= atom-count-after 12)))))  ; 6 C + 6 H

(test unfold-hydrogens-water
  "Test unfolding hydrogen atoms to water molecule."
  (with-molecule (mol "O")  ; Water
    ;; Count atoms before unfolding
    (let ((atom-count-before (count-atoms mol)))
      (is (= atom-count-before 1)))  ; Just O
    ;; Unfold hydrogens
    (is-true (unfold-hydrogens mol))
    ;; Count atoms after unfolding
    (let ((atom-count-after (count-atoms mol)))
      (is (= atom-count-after 3)))))  ; O + 2 H

;;;; =========================================================================
;;;; Combined Operations Tests
;;;; =========================================================================

(test aromatize-then-layout
  "Test combining aromatize and layout operations."
  (with-molecule (mol "C1=CC=CC=C1")  ; Kekule benzene
    ;; Aromatize first (returns :changed)
    (is (eq (aromatize mol) :changed))
    ;; Then calculate layout (returns t)
    (is-true (layout mol))
    ;; Should have coordinates
    (is-true (has-coordinates mol))))

(test unfold-layout-fold
  "Test unfold, layout, then fold sequence."
  (with-molecule (mol "CCO")  ; Ethanol
    ;; Unfold hydrogens
    (is-true (unfold-hydrogens mol))
    (let ((count-unfolded (count-atoms mol)))
      (is (> count-unfolded 3)))
    ;; Calculate layout
    (is-true (layout mol))
    (is-true (has-coordinates mol))
    ;; Fold hydrogens back
    (is-true (fold-hydrogens mol))
    (let ((count-folded (count-atoms mol)))
      (is (= count-folded 3)))
    ;; Should still have coordinates
    (is-true (has-coordinates mol))))

(test fold-unfold-roundtrip
  "Test fold/unfold roundtrip preserves structure."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    ;; Get initial SMILES
    (let ((smiles-initial (canonical-smiles mol)))
      ;; Unfold then fold
      (is-true (unfold-hydrogens mol))
      (is-true (fold-hydrogens mol))
      ;; SMILES should be the same
      (let ((smiles-after (canonical-smiles mol)))
        (is (string= smiles-initial smiles-after))))))

;;;; =========================================================================
;;;; Iterator Tests with Structure Manipulation
;;;; =========================================================================

(test iterate-after-unfold
  "Test iterating atoms after unfolding hydrogens."
  (with-molecule (mol "CC")  ; Ethane
    ;; Count atoms before unfold
    (let ((count-before (count-atoms mol)))
      (is (= count-before 2)))
    ;; Unfold hydrogens
    (is-true (unfold-hydrogens mol))
    ;; Iterate and count atoms manually
    (with-atoms-iterator (atoms-iter mol)
      (let ((count 0))
        (loop for atom = (indigo-next atoms-iter)
              while (and atom (> atom 0))
              do (incf count))
        ;; Should have 2 C + 6 H = 8 atoms
        (is (= count 8))))))
