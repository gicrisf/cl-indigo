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
