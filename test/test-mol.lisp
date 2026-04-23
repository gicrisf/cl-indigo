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

(test molecule-loading-multiple-types
  "Test loading various molecule types."
  (dolist (smiles '("CCO" "c1ccccc1" "O" "C" "CN1C=NC2=C1C(=O)N(C(=O)N2C)C"))
    (with-molecule (mol smiles)
      (is (integerp mol))
      (is (> mol 0)))))

(test query-molecule-loading
  "Test loading query molecules from strings."
  (with-query (query "c1ccccc1")
    (is (integerp query))
    (is (> query 0))))

(test clone-molecule
  "Test cloning molecule handles."
  (with-molecule (mol "CCO")
    (let ((cloned (indigo-clone mol)))
      (is (integerp cloned))
      (is (> cloned 0))
      (is (not (= mol cloned)))
      (indigo-free cloned))))

;;;; =========================================================================
;;;; Format Conversion Tests
;;;; =========================================================================

(test smiles-output
  "Test SMILES generation from handles."
  (with-molecule (mol "CCO")
    (let ((smi (smiles mol)))
      (is (stringp smi)))))

(test canonical-smiles-output
  "Test canonical SMILES generation from handles."
  (with-molecule (mol "CCO")
    (let ((smi (canonical-smiles mol)))
      (is (stringp smi))
      (is (or (string= smi "CCO")
              (string= smi "OCC"))))))

(test molfile-output
  "Test MOL file generation from handles."
  (with-molecule (mol "CCO")
    (let ((mf (molfile mol)))
      (is (stringp mf))
      (is (search "V2000" mf)))))

(test cml-output
  "Test CML generation from handles."
  (with-molecule (mol "CCO")
    (let ((cml-str (cml mol)))
      (is (stringp cml-str))
      (is (search "<molecule" cml-str)))))

(test format-conversions-single-molecule
  "Test multiple format conversions with single molecule."
  (let ((results
         (with-molecule (mol "CCO")
           (list
            :smiles (canonical-smiles mol)
            :molfile (molfile mol)
            :cml (cml mol)))))
    ;; Test SMILES
    (is (stringp (getf results :smiles)))
    (is (or (search "CCO" (getf results :smiles))
            (search "OCC" (getf results :smiles))))
    ;; Test MOL file
    (is (stringp (getf results :molfile)))
    (is (search "V2000" (getf results :molfile)))
    ;; Test CML
    (is (stringp (getf results :cml)))
    (is (search "<molecule" (getf results :cml)))))

;;;; =========================================================================
;;;; Numeric Property Tests
;;;; =========================================================================

(test molecular-weight
  "Test molecular weight calculation."
  (with-molecule (mol "CCO")  ; Ethanol: C2H6O = 46.069
    (let ((weight (molecular-weight mol)))
      (is (floatp weight))
      (is (float-equal weight 46.069 0.01)))))

(test gross-formula
  "Test gross formula generation."
  (with-molecule (mol "CCO")
    (let ((formula (gross-formula mol)))
      (is (stringp formula))
      (is (string= formula "C2 H6 O")))))

(test mass-calculations
  "Test mass calculation functions."
  (with-molecule (mol "CCO")  ; Ethanol
    ;; Test most abundant mass
    (let ((most-abundant (most-abundant-mass mol)))
      (is (floatp most-abundant))
      (is (> most-abundant 40.0))   ; Should be around 46
      (is (< most-abundant 50.0)))
    ;; Test monoisotopic mass
    (let ((monoisotopic (monoisotopic-mass mol)))
      (is (floatp monoisotopic))
      (is (> monoisotopic 40.0))    ; Should be around 46
      (is (< monoisotopic 50.0)))))

(test property-calculations
  "Test multiple property calculations with single molecule."
  (let ((results
         (with-molecule (mol "CCO")
           (list
            :weight (molecular-weight mol)
            :formula (gross-formula mol)
            :most-abundant (most-abundant-mass mol)
            :monoisotopic (monoisotopic-mass mol)))))
    ;; Test molecular weight
    (is (floatp (getf results :weight)))
    (is (> (getf results :weight) 40))
    (is (< (getf results :weight) 50))
    ;; Test gross formula
    (is (stringp (getf results :formula)))
    ;; Test masses
    (is (floatp (getf results :most-abundant)))
    (is (floatp (getf results :monoisotopic)))))

;;;; =========================================================================
;;;; Counting Function Tests
;;;; =========================================================================

(test count-atoms
  "Test atom counting."
  (with-molecule (mol "CCO")
    (is (= 3 (count-atoms mol)))))

(test count-bonds
  "Test bond counting."
  (with-molecule (mol "CCO")
    (is (= 2 (count-bonds mol)))))

(test count-implicit-hydrogens
  "Test implicit hydrogen counting from handles."
  (with-molecule (mol "CCO")
    (let ((count (count-implicit-hydrogens mol)))
      (is (integerp count))
      (is (>= count 0)))))

(test count-sssr
  "Test SSSR ring counting from handles."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (let ((count (count-sssr mol)))
      (is (integerp count))
      (is (= count 1)))))

(test count-stereocenters
  "Test stereocenter counting from handles."
  (with-molecule (mol "CCO")  ; No stereocenters
    (let ((count (count-stereocenters mol)))
      (is (integerp count))
      (is (>= count 0)))))

(test count-heavy-atoms-ethanol
  "Test heavy atom counting for ethanol."
  (with-molecule (mol "CCO")  ; Ethanol: 3 heavy atoms (C,C,O)
    (let ((heavy-count (count-heavy-atoms mol)))
      (is (integerp heavy-count))
      (is (= heavy-count 3)))))

(test count-heavy-atoms-benzene
  "Test heavy atom counting for benzene."
  (with-molecule (mol "c1ccccc1")  ; Benzene: 6 carbons
    (let ((heavy-count (count-heavy-atoms mol)))
      (is (integerp heavy-count))
      (is (= heavy-count 6)))))

(test counting-operations
  "Test multiple counting operations with single molecule."
  (let ((ethanol-counts
         (with-molecule (mol "CCO")
           (list
            :atoms (count-atoms mol)
            :bonds (count-bonds mol)
            :heavy-atoms (count-heavy-atoms mol)
            :hydrogens (count-implicit-hydrogens mol))))
        (benzene-counts
         (with-molecule (mol "c1ccccc1")
           (list
            :atoms (count-atoms mol)
            :rings (count-sssr mol)
            :heavy-atoms (count-heavy-atoms mol)))))
    ;; Ethanol tests
    (is (= (getf ethanol-counts :atoms) 3))
    (is (= (getf ethanol-counts :bonds) 2))
    (is (= (getf ethanol-counts :heavy-atoms) 3))
    ;; Benzene tests
    (is (= (getf benzene-counts :atoms) 6))
    (is (= (getf benzene-counts :rings) 1))
    (is (= (getf benzene-counts :heavy-atoms) 6))))

;;;; =========================================================================
;;;; Boolean Property Tests
;;;; =========================================================================

(test has-coordinates-before-layout
  "Test coordinate detection before layout."
  (with-molecule (mol "CCO")
    (is (not (has-coordinates mol)))))

(test has-coordinates-after-layout
  "Test coordinate detection after layout."
  (with-molecule (mol "CCO")
    (layout mol)
    (is (has-coordinates mol))))

(test has-z-coord-for-2d
  "Test 3D coordinate detection for 2D molecule."
  (with-molecule (mol "CCO")
    (layout mol)
    ;; After layout, should have 2D coords but not 3D
    (is (not (has-z-coord mol)))))

(test boolean-properties
  "Test multiple boolean property checks with single molecule."
  (let ((results
         (with-molecule (mol "CCO")
           (list
            :has-coords (has-coordinates mol)
            :has-z (has-z-coord mol)))))
    ;; All should return boolean values
    (is (or (eq (getf results :has-coords) t)
            (eq (getf results :has-coords) nil)))
    (is (or (eq (getf results :has-z) t)
            (eq (getf results :has-z) nil)))))

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
    (let ((smi (canonical-smiles mol)))
      ;; Should be aromatic notation
      (is (search "c" smi)))))

(test aromatize-return-status
  "Test aromatization return status."
  (with-molecule (mol "C1=CC=CC=C1")  ; Kekulé benzene
    (let ((result (aromatize mol)))
      (is (eq result :changed)))))

(test aromatize-unchanged
  "Test aromatization when already aromatic."
  (with-molecule (mol "c1ccccc1")  ; Already aromatic
    (aromatize mol)  ; First call may or may not change it
    (let ((result (aromatize mol)))  ; Second call should be unchanged
      (is (eq result :unchanged)))))

(test layout-return-value
  "Test layout return value."
  (with-molecule (mol "CCO")
    (let ((result (layout mol)))
      (is (eq result t)))))

;;;; =========================================================================
;;;; Normalization Tests
;;;; =========================================================================

(test normalize-basic
  "Test basic molecule normalization."
  (with-molecule (mol "[H]C([H])([H])C([H])([H])O[H]")  ; ethanol with explicit H
    (let ((result (normalize mol)))
      (is (eq result :changed))  ; Explicit H should be removed
      ;; Check that normalization worked
      (let ((normalized-smiles (smiles mol)))
        (is (stringp normalized-smiles))))))

(test normalize-with-options
  "Test molecule normalization with options."
  (with-molecule (mol "[H]C([H])([H])C([H])([H])O[H]")
    (let ((result (normalize mol "")))
      (is (eq result :changed))
      (let ((normalized-smiles (smiles mol)))
        (is (stringp normalized-smiles))))))

(test normalize-error-handling
  "Test normalization error handling with invalid handle."
  (signals indigo-error
    (normalize -1)))

(test standardize-basic
  "Test basic molecule standardization."
  (with-molecule (mol "[H]N([H])C([H])([H])C(=O)O[H]")  ; glycine with explicit H
    (let ((result (standardize mol)))
      (is (keywordp result))
      (is (member result '(:changed :unchanged)))
      ;; Check that molecule is still valid
      (let ((smi (smiles mol)))
        (is (stringp smi))))))

(test standardize-error-handling
  "Test standardization error handling with invalid handle."
  (signals indigo-error
    (standardize -1)))

(test ionize-basic
  "Test basic molecule ionization."
  (with-molecule (mol "CC(=O)O")  ; acetic acid
    (let ((result (ionize mol 7.0 0.1)))  ; pH 7.0 with tolerance 0.1
      (is (eq result :changed))  ; Acetic acid should be deprotonated at pH 7
      ;; Check that molecule is still valid
      (let ((smi (smiles mol)))
        (is (stringp smi))
        ;; Should contain negative charge for deprotonated carboxyl
        (is (search "[O-]" smi))))))

(test ionize-acidic-ph
  "Test molecule ionization at acidic pH."
  (with-molecule (mol "CC(=O)O")  ; acetic acid
    (let ((result (ionize mol 3.0 0.1)))
      (is (keywordp result))
      (is (member result '(:changed :unchanged))))))

(test ionize-basic-ph
  "Test molecule ionization at basic pH."
  (with-molecule (mol "CC(=O)O")  ; acetic acid
    (let ((result (ionize mol 10.0 0.1)))
      (is (eq result :changed)))))

(test ionize-error-handling
  "Test ionization error handling with invalid handle."
  (signals indigo-error
    (ionize -1 7.0 0.1)))

(test normalization-error-handling-all
  "Test error handling with invalid molecule handles for all normalization."
  (signals indigo-error (normalize -1))
  (signals indigo-error (standardize -1))
  (signals indigo-error (ionize -1 7.0 0.1)))

;;;; =========================================================================
;;;; Hydrogen Handling Tests
;;;; =========================================================================

(test fold-hydrogens-basic
  "Test folding explicit hydrogens."
  (with-molecule (mol "CCO")
    (unfold-hydrogens mol)
    (let ((unfolded-count (count-atoms mol)))
      (is (= unfolded-count 9))  ; 3 heavy + 6 H
      (fold-hydrogens mol)
      (is (= (count-atoms mol) 3)))))  ; Only heavy atoms

(test unfold-hydrogens-basic
  "Test unfolding implicit hydrogens."
  (with-molecule (mol "CCO")
    (is (= (count-atoms mol) 3))  ; Only heavy atoms
    (unfold-hydrogens mol)
    (is (= (count-atoms mol) 9))))  ; 3 heavy + 6 H

(test hydrogen-roundtrip
  "Test hydrogen fold/unfold roundtrip."
  (with-molecule (mol "CCO")
    (let ((original-count (count-atoms mol)))
      (unfold-hydrogens mol)
      (fold-hydrogens mol)
      (is (= (count-atoms mol) original-count)))))

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

(test with-molecule-star-cleanup
  "Test that with-molecule* properly cleans up all molecules."
  (ignore-errors
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1")
                     (mol3 "CCC"))
      (error "Test error")))
  ;; If cleanup didn't happen, subsequent operations would fail
  (with-molecule* ((mol1 "CCO")
                   (mol2 "c1ccccc1"))
    (is (integerp mol1))
    (is (integerp mol2))))

(test molecule-star-sequential-evaluation
  "Test that with-molecule* evaluates bindings sequentially."
  (let ((created-mols nil))
    (ignore-errors
      (with-molecule* ((mol1 "CCO")
                       (mol2 "c1ccccc1")
                       (mol3 "CCC"))
        ;; All three molecules should be valid at this point
        (setf created-mols (list mol1 mol2 mol3))
        (is (integerp mol1))
        (is (integerp mol2))
        (is (integerp mol3))
        (is (> mol1 0))
        (is (> mol2 0))
        (is (> mol3 0))
        ;; Force an error to test cleanup
        (error "Test error")))
    ;; Verify molecules were created
    (is-true created-mols)
    (is (= (length created-mols) 3))))

(test plural-vs-nested-singular
  "Compare plural macros with nested singular macros for equivalence."
  ;; Test with plural macros
  (let ((result-plural
         (with-molecule* ((mol1 "CCO")
                          (mol2 "c1ccccc1"))
           (list (molecular-weight mol1)
                 (molecular-weight mol2)))))

    ;; Test with nested singular macros
    (let ((result-nested
           (with-molecule (mol1 "CCO")
             (with-molecule (mol2 "c1ccccc1")
               (list (molecular-weight mol1)
                     (molecular-weight mol2))))))

      ;; Both should produce the same results
      (is (= (length result-plural) (length result-nested)))
      (is (< (abs (- (first result-plural) (first result-nested))) 0.001))
      (is (< (abs (- (second result-plural) (second result-nested))) 0.001)))))

;;;; =========================================================================
;;;; Fingerprint and Similarity Tests
;;;; =========================================================================

(test fingerprint-generation
  "Test fingerprint generation from handles."
  (with-molecule (mol "CCO")
    (with-fingerprint (fp mol "sim")
      (is (integerp fp))
      (is (> fp 0)))))

(test similarity-tanimoto
  "Test Tanimoto similarity calculation."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCO"))
    (with-fingerprint* ((fp1 mol1 "sim")
                        (fp2 mol2 "sim"))
      (let ((sim (similarity fp1 fp2 :tanimoto)))
        (is (floatp sim))
        (is (>= sim 0.0))
        (is (<= sim 1.0))
        ;; Same molecule should have similarity 1.0
        (is (> sim 0.99))))))

(test similarity-default
  "Test default similarity calculation (should use Tanimoto)."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCO"))
    (with-fingerprint* ((fp1 mol1 "sim")
                        (fp2 mol2 "sim"))
      (let ((sim-default (similarity fp1 fp2))
            (sim-explicit (similarity fp1 fp2 :tanimoto)))
        (is (floatp sim-default))
        (is (= sim-default sim-explicit))))))

(test similarity-tversky
  "Test Tversky similarity with custom parameters."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CC(O)C"))
    (with-fingerprint* ((fp1 mol1 "sim")
                        (fp2 mol2 "sim"))
      ;; Test basic tversky (default parameters)
      (let ((sim-default (similarity fp1 fp2 :tversky)))
        (is (floatp sim-default))
        (is (>= sim-default 0.0))
        (is (<= sim-default 1.0)))
      ;; Test tversky with custom parameters
      (let ((sim-custom (similarity fp1 fp2 :tversky 0.7 0.3)))
        (is (floatp sim-custom))
        (is (>= sim-custom 0.0))
        (is (<= sim-custom 1.0))))))

(test fingerprint-similarity-comparison
  "Test fingerprint similarity calculation with with-* macros."
  (with-molecule (mol1 "CCO")
    (with-fingerprint (fp1 mol1 "sim")
      (with-molecule (mol2 "CCO")
        (with-fingerprint (fp2 mol2 "sim")
          (let ((sim (similarity fp1 fp2 :tanimoto)))
            (is (floatp sim))
            (is (> sim 0.99))))))))

(test with-fingerprint-star
  "Test with-fingerprint* macro with multiple fingerprints."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "c1ccccc1")
                   (mol3 "CCC"))
    (with-fingerprint* ((fp1 mol1 "sim")
                        (fp2 mol2 "sim")
                        (fp3 mol3 "sim"))
      (is (integerp fp1))
      (is (> fp1 0))
      (is (integerp fp2))
      (is (> fp2 0))
      (is (integerp fp3))
      (is (> fp3 0))
      ;; Test similarity calculations
      (let ((sim12 (similarity fp1 fp2))
            (sim13 (similarity fp1 fp3)))
        (is (floatp sim12))
        (is (floatp sim13))
        ;; CCO and CCC should be more similar than CCO and benzene
        (is (> sim13 sim12))))))

;;;; =========================================================================
;;;; Matching Tests
;;;; =========================================================================

(test exact-match-same
  "Test exact matching between identical molecules."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCO"))
    (is-true (exact-match mol1 mol2))))

(test exact-match-different
  "Test exact matching between different molecules."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "CCC"))
    (let ((result (exact-match mol1 mol2)))
      (is (not result)))))

(test substructure-matcher-creation
  "Test substructure matcher creation from handles."
  (with-molecule (mol "CCO")
    (with-matcher (matcher mol)
      (is (integerp matcher))
      (is (> matcher 0)))))

(test substructure-matching
  "Test substructure matching with with- macros."
  (with-molecule (target "c1ccccc1CC")  ; Ethylbenzene
    (with-query (query "c1ccccc1")      ; Benzene ring
      (with-matcher (matcher target)
        (is (integerp matcher))
        (is (> matcher 0))))))

(test with-matcher-star
  "Test with-matcher* macro with multiple matchers."
  (with-molecule* ((mol1 "c1ccccc1CCO")  ; Phenylethanol
                   (mol2 "CCN"))          ; Ethylamine
    (with-matcher* ((matcher1 mol1)
                    (matcher2 mol2))
      (is (integerp matcher1))
      (is (> matcher1 0))
      (is (integerp matcher2))
      (is (> matcher2 0)))))

(test exact-matching-with-plural-macro
  "Test exact matching with plural macro."
  (let ((match-same
         (with-molecule* ((mol1 "CCO")
                          (mol2 "CCO"))
           (exact-match mol1 mol2)))
        (match-different
         (with-molecule* ((mol1 "CCO")
                          (mol2 "CCC"))
           (exact-match mol1 mol2))))
    (is-true match-same)
    (is-false match-different)))

;;;; =========================================================================
;;;; With-Macro Tests (Query, SMARTS)
;;;; =========================================================================

(test with-query-basic
  "Test with-query macro."
  (with-query (query "C=O")
    (is (integerp query))
    (is (> query 0))))

(test with-smarts-basic
  "Test with-smarts macro."
  (with-smarts (pattern "[#6]=[#8]")
    (is (integerp pattern))
    (is (> pattern 0))))

(test with-query-star
  "Test with-query* macro with multiple query molecules."
  (with-query* ((query1 "C=O")
                (query2 "C#N"))
    (is (integerp query1))
    (is (> query1 0))
    (is (integerp query2))
    (is (> query2 0))
    (let ((smiles1 (smiles query1))
          (smiles2 (smiles query2)))
      (is (stringp smiles1))
      (is (stringp smiles2)))))

(test with-smarts-star
  "Test with-smarts* macro with multiple SMARTS patterns."
  (with-smarts* ((pattern1 "[#6]=[#8]")
                 (pattern2 "[#7]"))
    (is (integerp pattern1))
    (is (> pattern1 0))
    (is (integerp pattern2))
    (is (> pattern2 0))
    (let ((smiles1 (smiles pattern1))
          (smiles2 (smiles pattern2)))
      (is (stringp smiles1))
      (is (stringp smiles2)))))

;;;; =========================================================================
;;;; Resource Cleanup Tests
;;;; =========================================================================

(test with-molecule-automatic-cleanup
  "Test that with-molecule properly cleans up resources."
  (let ((initial-refs (count-references)))
    (with-molecule (mol "CCO")
      ;; Inside scope: 1 molecule allocated
      (is (= (count-references) (+ initial-refs 1))))
    ;; Outside scope: resources should be freed
    (is (= (count-references) initial-refs))))

(test with-molecule-star-automatic-cleanup
  "Test that with-molecule* properly cleans up multiple resources."
  (let ((initial-refs (count-references)))
    (with-molecule* ((mol1 "CCO")
                     (mol2 "c1ccccc1"))
      ;; Inside scope: 2 molecules allocated
      (is (= (count-references) (+ initial-refs 2))))
    ;; Outside scope: all resources should be freed
    (is (= (count-references) initial-refs))))

(test with-molecule-iterator-cleanup
  "Test cleanup with nested molecule and iterator macros."
  (let ((initial-refs (count-references)))
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        ;; Inside scope: molecule + iterator allocated
        (is (>= (count-references) (+ initial-refs 1)))))
    ;; Outside scope: all resources should be freed
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Error Handling Tests
;;;; =========================================================================

(test with-molecule-invalid-smiles
  "Test that with-molecule signals error for invalid SMILES."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule (mol "INVALID_SMILES")
        (declare (ignore mol))
        nil))
    ;; Resources should still be cleaned up after error
    (is (= (count-references) initial-refs))))

(test with-molecule-star-invalid-smiles
  "Test that with-molecule* properly cleans up when later molecule fails."
  (let ((initial-refs (count-references)))
    (signals indigo-error
      (with-molecule* ((mol1 "CCO")
                       (mol2 "INVALID_SMILES"))
        (declare (ignore mol1 mol2))
        nil))
    ;; With sequential nesting, mol1 should be cleaned up even when mol2 fails
    (is (= (count-references) initial-refs))))

(test with-molecule-error-in-body
  "Test cleanup when error occurs in macro body."
  (let ((initial-refs (count-references)))
    (ignore-errors
      (with-molecule (mol "CCO")
        (declare (ignore mol))
        (error "Test error in body")))
    ;; Resources should still be cleaned up
    (is (= (count-references) initial-refs))))

;;;; =========================================================================
;;;; Iterator Dependency Tests
;;;; =========================================================================

(test with-atoms-iterator-dependency
  "Test atoms iterator depending on molecule."
  (let ((symbols
         (with-molecule (mol "CCO")
           (with-atoms-iterator (atoms mol)
             (loop for atom = (indigo-next atoms)
                   while (and atom (> atom 0))
                   collect (atom-symbol atom))))))
    (is (equal symbols '("C" "C" "O")))))

(test with-bonds-iterator-dependency
  "Test bonds iterator depending on molecule."
  (let ((bond-count
         (with-molecule (mol "CCO")
           (with-bonds-iterator (bonds mol)
             (loop for bond = (indigo-next bonds)
                   while (and bond (> bond 0))
                   count t)))))
    (is (= bond-count 2))))

(test with-components-iterator-dependency
  "Test components iterator with multi-component molecule."
  (let ((comp-count
         (with-molecule (mol "CCO.CC")  ; Two components
           (with-components-iterator (comps mol)
             (loop for comp = (indigo-next comps)
                   while (and comp (> comp 0))
                   count t)))))
    (is (= comp-count 2))))

(test with-sssr-iterator-dependency
  "Test SSSR iterator depending on molecule."
  (let ((ring-count
         (with-molecule (mol "c1ccccc1")  ; Benzene - 1 ring
           (with-sssr-iterator (rings mol)
             (loop for ring = (indigo-next rings)
                   while (and ring (> ring 0))
                   count t)))))
    (is (= ring-count 1))))

(test with-stereocenters-iterator-dependency
  "Test stereocenters iterator depending on molecule."
  (let ((stereocenter-count
         (with-molecule (mol "C[C@H](O)CC")  ; 1 stereocenter
           (with-stereocenters-iterator (stereos mol)
             (loop for stereo = (indigo-next stereos)
                   while (and stereo (> stereo 0))
                   count t)))))
    (is (= stereocenter-count 1))))

;;;; =========================================================================
;;;; Complex Workflow Tests
;;;; =========================================================================

(test complex-workflow
  "Test complex workflow with multiple resources and calculations."
  (let ((analysis
         (with-molecule* ((ethanol "CCO")
                          (methanol "CO"))
           (with-fingerprint* ((eth-fp ethanol "sim")
                               (met-fp methanol "sim"))
             (with-atoms-iterator (eth-atoms ethanol)
               (let ((ethanol-atoms-list
                      (loop for atom = (indigo-next eth-atoms)
                            while (and atom (> atom 0))
                            collect (atom-symbol atom))))
                 (list
                  :ethanol-weight (molecular-weight ethanol)
                  :methanol-weight (molecular-weight methanol)
                  :similarity (similarity eth-fp met-fp)
                  :ethanol-atoms ethanol-atoms-list
                  :atom-count (length ethanol-atoms-list))))))))

    (is (getf analysis :ethanol-weight))
    (is (getf analysis :methanol-weight))
    (is (numberp (getf analysis :similarity)))
    (is (equal (getf analysis :ethanol-atoms) '("C" "C" "O")))
    (is (= (getf analysis :atom-count) 3))))

(test clone-operation-workflow
  "Test molecule cloning with with- macros."
  (with-molecule (mol "CCO")
    (let ((cloned (indigo-clone mol)))
      (unwind-protect
          (progn
            (is (integerp cloned))
            (is (> cloned 0))
            (is (not (= mol cloned)))
            ;; Both should have same properties
            (is (= (count-atoms mol)
                   (count-atoms cloned))))
        (indigo-free cloned)))))

(test multiple-format-operations
  "Test multiple format conversions in sequence."
  (let ((conversions
         (with-molecule (mol "c1ccccc1")
           ;; Do multiple conversions without worrying about cleanup
           (list
            (canonical-smiles mol)
            (smiles mol)
            (gross-formula mol)))))
    (is (= (length conversions) 3))
    (is (every #'stringp conversions))))

;;;; =========================================================================
;;;; With-Molecule Nested Tests
;;;; =========================================================================

(test with-molecule-nested
  "Test nested with-molecule macros."
  (let ((result (with-molecule (mol1 "CCO")
                  (with-molecule (mol2 "c1ccccc1")
                    (list (molecular-weight mol1)
                          (molecular-weight mol2))))))
    (is (listp result))
    (is (= (length result) 2))
    (is (< (abs (- (first result) 46.069)) 0.01))
    (is (< (abs (- (second result) 78.114)) 0.01))))

(test with-molecule-error-cleanup
  "Test that with-molecule cleans up on error."
  (ignore-errors
    (with-molecule (mol "CCO")
      (declare (ignore mol))
      (error "Test error")))
  ;; If cleanup didn't happen, subsequent operations would fail
  (with-molecule (mol "CCO")
    (is (integerp mol))))

(test similarity-comparison-workflow
  "Test comparing fingerprints with plural macros."
  (with-molecule* ((mol1 "CCO")
                   (mol2 "c1ccccc1"))
    (with-fingerprint* ((fp1 mol1 "sim")
                        (fp2 mol2 "sim"))
      (let ((sim (similarity fp1 fp2)))
        (is (floatp sim))
        (is (>= sim 0.0))
        (is (<= sim 1.0))))))
