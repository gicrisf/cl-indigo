;;;; test-io.lisp - Tests for I/O operations

(in-package #:cl-indigo-tests)

(def-suite io-tests
  :description "Tests for I/O operations"
  :in :cl-indigo-tests)

(in-suite io-tests)

;;;; =========================================================================
;;;; Molecule Creation Tests
;;;; =========================================================================

(test create-molecule
  "Test creating empty molecule."
  (let ((mol (create-molecule)))
    (is (integerp mol))
    (is (> mol 0))
    (indigo-free mol)))

(test create-molecule-cleanup
  "Test that created molecule can be freed without error."
  (with-reference-check
    (let ((mol (create-molecule)))
      (is (> mol 0))
      (indigo-free mol))))

(test create-query-molecule
  "Test creating empty query molecule."
  (let ((qmol (create-query-molecule)))
    (is (integerp qmol))
    (is (> qmol 0))
    (indigo-free qmol)))

;;;; =========================================================================
;;;; File Loading Tests
;;;; =========================================================================

(test load-molecule-from-file
  "Test loading molecule from file."
  (with-temp-file (temp-file "test-mol" ".smi")
    ;; Write test SMILES to file
    (write-file-contents temp-file "CCO ethanol")
    ;; Load molecule from file
    (let ((mol (load-molecule-from-file temp-file)))
      (is (integerp mol))
      (is (> mol 0))
      ;; Verify it's ethanol by checking canonical SMILES
      (let ((smi (canonical-smiles mol)))
        (is (stringp smi))
        (is (or (search "CCO" smi)
                (search "OCC" smi))))
      (indigo-free mol))))

(test load-query-molecule-from-file
  "Test loading query molecule from file."
  (with-temp-file (temp-file "test-query" ".smi")
    ;; Write test SMARTS to file
    (write-file-contents temp-file "c1ccccc1")
    ;; Load query molecule from file
    (let ((qmol (load-query-molecule-from-file temp-file)))
      (is (integerp qmol))
      (is (> qmol 0))
      (indigo-free qmol))))

;;;; =========================================================================
;;;; SMARTS Loading Tests
;;;; =========================================================================

(test load-smarts-from-string
  "Test loading SMARTS from string."
  (let ((smarts (load-smarts-from-string "c1ccccc1")))
    (is (integerp smarts))
    (is (> smarts 0))
    (indigo-free smarts)))

(test load-smarts-from-file
  "Test loading SMARTS from file."
  (with-temp-file (temp-file "test-smarts" ".smi")
    ;; Write test SMARTS to file
    (write-file-contents temp-file "c1ccccc1")
    ;; Load SMARTS from file
    (let ((smarts (load-smarts-from-file temp-file)))
      (is (integerp smarts))
      (is (> smarts 0))
      (indigo-free smarts))))

;;;; =========================================================================
;;;; File Saving Tests
;;;; =========================================================================

(test save-molfile-to-file
  "Test saving molecule to file in MOL format."
  (with-molecule (mol "CCO")
    (with-temp-file (temp-file "test-output" ".mol")
      ;; Save molecule to file
      (let ((result (save-molfile-to-file mol temp-file)))
        (is (integerp result))
        ;; Check that file was created and has content
        (is (probe-file temp-file))
        (let ((content (read-file-contents temp-file)))
          (is (stringp content))
          (is (> (length content) 0))
          ;; MOL files should have M END marker
          (is (search "M  END" content)))))))

(test save-molfile-roundtrip
  "Test saving and loading molecule preserves structure."
  (with-molecule (mol1 "CCO")
    (with-temp-file (temp-file "test-roundtrip" ".mol")
      (save-molfile-to-file mol1 temp-file)
      ;; Load it back
      (let ((mol2 (load-molecule-from-file temp-file)))
        (is (integerp mol2))
        (is (> mol2 0))
        ;; Verify atom count is preserved
        (is (= (count-atoms mol1) (count-atoms mol2)))
        (indigo-free mol2)))))

;;;; =========================================================================
;;;; Error Handling Tests
;;;; =========================================================================

(test load-molecule-from-file-nonexistent
  "Test loading molecule from non-existent file signals error."
  (signals indigo-error
    (load-molecule-from-file "/nonexistent/path/file.smi")))

(test load-invalid-smiles-error
  "Test loading invalid SMILES signals error."
  (signals indigo-error
    (load-molecule-from-string "INVALID_SMILES")))

(test load-smarts-invalid-error
  "Test loading invalid SMARTS signals error."
  (signals indigo-error
    (load-smarts-from-string "[INVALID")))

;;;; =========================================================================
;;;; File Roundtrip Tests
;;;; =========================================================================

(test file-roundtrip-benzene
  "Test loading molecule from file, modifying it, and saving back."
  (with-temp-file (temp-input "test-input" ".smi")
    (with-temp-file (temp-output "test-output" ".mol")
      ;; Create input file
      (write-file-contents temp-input "c1ccccc1 benzene")
      ;; Load, verify, and save
      (let ((mol (load-molecule-from-file temp-input)))
        (is (integerp mol))
        (is (> mol 0))
        ;; Verify it loaded correctly
        (let ((smi (canonical-smiles mol)))
          (is (stringp smi))
          (is (or (search "c1ccccc1" smi)
                  (search "C1=CC=CC=C1" smi))))
        ;; Save to MOL file
        (let ((result (save-molfile-to-file mol temp-output)))
          (is (integerp result))
          (is (probe-file temp-output)))
        (indigo-free mol)))))

;;;; =========================================================================
;;;; Integration Tests - SMARTS Loading
;;;; =========================================================================

(test integration-smarts-loading
  "Test loading and using SMARTS patterns."
  (let ((benzene-smarts "c1ccccc1")
        (alcohol-smarts "[OH]"))
    ;; Test benzene pattern
    (let ((smarts1 (load-smarts-from-string benzene-smarts)))
      (is (integerp smarts1))
      (is (> smarts1 0))
      (indigo-free smarts1))
    ;; Test alcohol pattern
    (let ((smarts2 (load-smarts-from-string alcohol-smarts)))
      (is (integerp smarts2))
      (is (> smarts2 0))
      (indigo-free smarts2))))

;;;; =========================================================================
;;;; Public API Error Handling Tests
;;;; =========================================================================

(test public-api-cleanup-on-error
  "Test that public API cleans up resources even when errors occur."
  (let ((initial-refs (count-references)))
    ;; Error during molecule loading
    (signals indigo-error
      (load-molecule-from-string "INVALID"))
    (is (= (count-references) initial-refs))
    ;; Error during file loading
    (signals indigo-error
      (load-molecule-from-file "/nonexistent"))
    (is (= (count-references) initial-refs))))

(test public-api-error-messages
  "Test that public API provides meaningful error messages."
  (handler-case
      (progn
        (load-molecule-from-string "INVALID_SMILES")
        (fail "Should have signaled an error"))
    (indigo-error (e)
      ;; Error should have a message
      (is (stringp (indigo-error-message e)))
      (is (> (length (indigo-error-message e)) 0)))))

(test public-api-valid-operations
  "Test that public API works correctly for valid inputs."
  ;; Create molecule
  (let ((mol (create-molecule)))
    (is (integerp mol))
    (is (> mol 0))
    (indigo-free mol))
  ;; Load molecule from string
  (let ((mol (load-molecule-from-string "CCO")))
    (is (integerp mol))
    (is (> mol 0))
    (is (= (count-atoms mol) 3))
    (indigo-free mol))
  ;; Load query molecule
  (let ((query (load-query-molecule-from-string "c1ccccc1")))
    (is (integerp query))
    (is (> query 0))
    (indigo-free query))
  ;; Load reaction
  (let ((rxn (load-reaction-from-string "CCO.CC>>CCOC")))
    (is (integerp rxn))
    (is (> rxn 0))
    (indigo-free rxn)))

(test public-api-iterators
  "Test that public API iterator creation works correctly."
  (with-molecule (mol "CCO")
    ;; Atoms iterator
    (with-atoms-iterator (atoms mol)
      (is (integerp atoms))
      (is (> atoms 0)))
    ;; Bonds iterator
    (with-bonds-iterator (bonds mol)
      (is (integerp bonds))
      (is (> bonds 0)))
    ;; SSSR iterator
    (with-sssr-iterator (sssr mol)
      (is (integerp sssr))
      (is (> sssr 0)))))

(test public-api-fingerprint-and-matcher
  "Test that public API fingerprint and matcher creation works."
  (with-molecule (mol "CCO")
    ;; Fingerprint
    (with-fingerprint (fp mol "sim")
      (is (integerp fp))
      (is (> fp 0)))
    ;; Substructure matcher
    (with-matcher (matcher mol)
      (is (integerp matcher))
      (is (> matcher 0)))))

(test public-api-array-creation
  "Test that public API array creation works."
  (let ((arr (create-array)))
    (is (integerp arr))
    (is (> arr 0))
    (indigo-free arr)))

;;;; =========================================================================
;;;; Array Operations Tests
;;;; =========================================================================

(test array-add-molecules
  "Test adding molecules to an array."
  (let ((arr (create-array)))
    (with-molecule (mol1 "CCO")
      (with-molecule (mol2 "CCC")
        (let ((result1 (array-add arr mol1))
              (result2 (array-add arr mol2)))
          (is (integerp result1))
          (is (integerp result2)))))
    (indigo-free arr)))

;;;; =========================================================================
;;;; Resource Management Tests
;;;; =========================================================================

(test io-resource-cleanup
  "Test that all I/O operations properly clean up resources."
  (with-reference-check
    ;; Test molecule creation and cleanup
    (let ((mol (create-molecule)))
      (indigo-free mol))
    ;; Test query molecule creation and cleanup
    (let ((qmol (create-query-molecule)))
      (indigo-free qmol))
    ;; Test array creation and cleanup
    (let ((arr (create-array)))
      (indigo-free arr))))

(test io-with-molecule-file-operations
  "Test file operations within with-molecule scope."
  (with-reference-check
    (with-temp-file (temp-file "test-mol" ".mol")
      (with-molecule (mol "CCO")
        (save-molfile-to-file mol temp-file)
        (is (probe-file temp-file))
        ;; Verify MOL file content
        (let ((content (read-file-contents temp-file)))
          (is (search "M  END" content)))))))

;;;; =========================================================================
;;;; Integration Tests (require test data files)
;;;; =========================================================================

(test integration-load-mol-file
  "Test loading molecules from MOL files."
  (let ((mol-file (test-file "molecules/chebi/ChEBI_10305.mol")))
    (when (probe-file mol-file)
      (let ((mol (load-molecule-from-file mol-file)))
        (is (integerp mol))
        (is (> mol 0))
        (let ((weight (molecular-weight mol))
              (formula (gross-formula mol))
              (atom-count (count-atoms mol))
              (bond-count (count-bonds mol))
              (smi (canonical-smiles mol))
              (mf (molfile mol)))
          (is (numberp weight))
          (is (> weight 0))
          (is (stringp formula))
          (is (> (length formula) 0))
          (is (integerp atom-count))
          (is (> atom-count 0))
          (is (integerp bond-count))
          (is (>= bond-count 0))
          (is (stringp smi))
          (is (> (length smi) 0))
          (is (stringp mf))
          (is (search "M  END" mf)))
        (indigo-free mol)))))

(test integration-load-multiple-chebi-files
  "Test loading multiple ChEBI molecules and comparing properties."
  (let ((chebi-files '("molecules/chebi/ChEBI_10305.mol"
                       "molecules/chebi/ChEBI_10909.mol"
                       "molecules/chebi/ChEBI_12211.mol"))
        (results '()))
    (dolist (filename chebi-files)
      (let ((mol-file (test-file filename)))
        (when (probe-file mol-file)
          (let ((mol (load-molecule-from-file mol-file)))
            (when (and (integerp mol) (> mol 0))
              (let ((weight (molecular-weight mol))
                    (atom-count (count-atoms mol)))
                (when (> weight 0)
                  (push (list filename weight atom-count) results))
                (indigo-free mol)))))))
    (is (> (length results) 0))
    (dolist (result results)
      (is (> (nth 1 result) 0))
      (is (> (nth 2 result) 0)))))

(test integration-load-sdf-file
  "Test loading molecules from SDF files."
  (let ((sdf-file (test-file "molecules/basic/sugars.sdf")))
    (when (probe-file sdf-file)
      (let ((mol (load-molecule-from-file sdf-file)))
        (is (integerp mol))
        (is (> mol 0))
        (let ((formula (gross-formula mol))
              (has-coords (has-coordinates mol))
              (ring-count (count-sssr mol)))
          (is (stringp formula))
          (is (booleanp has-coords))
          (is (integerp ring-count))
          (is (>= ring-count 0)))
        (indigo-free mol)))))

(test integration-file-saving-roundtrip
  "Test loading a molecule, saving it, and loading it back."
  (let ((input-file (test-file "molecules/chebi/ChEBI_7750.mol")))
    (when (probe-file input-file)
      (with-temp-file (temp-output "indigo-roundtrip" ".mol")
        ;; Load original molecule
        (let ((mol1 (load-molecule-from-file input-file)))
          (is (integerp mol1))
          (is (> mol1 0))
          (let ((original-formula (gross-formula mol1))
                (original-weight (molecular-weight mol1)))
            ;; Save molecule
            (let ((save-result (save-molfile-to-file mol1 temp-output)))
              (is (integerp save-result))
              (is (probe-file temp-output))
              ;; Load saved molecule
              (let ((mol2 (load-molecule-from-file temp-output)))
                (is (integerp mol2))
                (is (> mol2 0))
                (let ((saved-formula (gross-formula mol2))
                      (saved-weight (molecular-weight mol2)))
                  (is (string= original-formula saved-formula))
                  (is (= original-weight saved-weight)))
                (indigo-free mol2)))
            (indigo-free mol1)))))))

(test integration-stereochemistry-handling
  "Test loading molecules with stereochemistry information."
  (let ((stereo-file (test-file "molecules/stereo/enhanced_stereo1.mol")))
    (when (probe-file stereo-file)
      (let ((mol (load-molecule-from-file stereo-file)))
        (is (integerp mol))
        (is (> mol 0))
        (let ((stereo-count (count-stereocenters mol)))
          (is (integerp stereo-count))
          (is (>= stereo-count 0)))
        (indigo-free mol)))))

(test integration-query-molecule-loading
  "Test loading query molecules for substructure search."
  (let ((query-file (test-file "molecules/sss/arom_het_5_21.mol")))
    (when (probe-file query-file)
      (let ((qmol (load-query-molecule-from-file query-file)))
        (is (integerp qmol))
        (is (> qmol 0))
        (let ((target-file (test-file "molecules/chebi/ChEBI_10305.mol")))
          (when (probe-file target-file)
            (let ((target-mol (load-molecule-from-file target-file)))
              (is (integerp target-mol))
              (is (> target-mol 0))
              (let ((matcher (substructure-matcher target-mol)))
                (is (integerp matcher))
                (indigo-free matcher))
              (indigo-free target-mol))))
        (indigo-free qmol)))))

(test integration-sgroups-handling
  "Test loading molecules with S-groups."
  (let ((sgroup-file (test-file "molecules/sgroups/all_sgroups.sdf")))
    (when (probe-file sgroup-file)
      (let ((mol (load-molecule-from-file sgroup-file)))
        (is (integerp mol))
        (is (> mol 0))
        (let ((atom-count (count-atoms mol))
              (mf (molfile mol)))
          (is (integerp atom-count))
          (is (> atom-count 0))
          (is (stringp mf))
          (is (> (length mf) 0)))
        (indigo-free mol)))))
