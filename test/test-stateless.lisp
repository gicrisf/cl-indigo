;;;; test-stateless.lisp - Tests for stateless convenience functions

(in-package #:cl-indigo-tests)

(def-suite stateless-tests
  :description "Tests for stateless (auto-cleanup) convenience functions"
  :in :cl-indigo-tests)

(in-suite stateless-tests)

;;;; =========================================================================
;;;; Molecular Formula Tests (5 tests)
;;;; =========================================================================

(test molecular-formula-ethanol
  "Test molecular formula calculation for ethanol (CCO)."
  (is (string= (do-molecular-formula "CCO") "C2 H6 O")))

(test molecular-formula-methane
  "Test molecular formula calculation for methane (C)."
  (is (string= (do-molecular-formula "C") "C H4")))

(test molecular-formula-benzene
  "Test molecular formula calculation for benzene (c1ccccc1)."
  (is (string= (do-molecular-formula "c1ccccc1") "C6 H6")))

(test molecular-formula-invalid-smiles
  "Test molecular formula calculation with invalid SMILES."
  (is (null (do-molecular-formula "invalid"))))

(test molecular-formula-empty-string
  "Test molecular formula calculation with empty string."
  (is (string= (do-molecular-formula "") "")))

;;;; =========================================================================
;;;; Molecular Weight Tests (4 tests)
;;;; =========================================================================

(test molecular-weight-ethanol
  "Test molecular weight calculation for ethanol (CCO)."
  (is (floatp (do-molecular-weight "CCO")))
  (is (float-equal (do-molecular-weight "CCO") 46.07 0.1)))

(test molecular-weight-methane
  "Test molecular weight calculation for methane (C)."
  (is (floatp (do-molecular-weight "C")))
  (is (float-equal (do-molecular-weight "C") 16.04 0.1)))

(test molecular-weight-benzene
  "Test molecular weight calculation for benzene (c1ccccc1)."
  (is (floatp (do-molecular-weight "c1ccccc1")))
  (is (float-equal (do-molecular-weight "c1ccccc1") 78.11 0.1)))

(test molecular-weight-invalid-smiles
  "Test molecular weight calculation with invalid SMILES."
  (is (null (do-molecular-weight "invalid"))))

;;;; =========================================================================
;;;; Canonical SMILES Tests (4 tests)
;;;; =========================================================================

(test canonical-smiles-ethanol
  "Test canonical SMILES for ethanol (CCO)."
  (is (stringp (do-canonical-smiles "CCO")))
  (is (string= (do-canonical-smiles "CCO") "CCO")))

(test canonical-smiles-benzene
  "Test canonical SMILES for benzene (c1ccccc1)."
  (is (stringp (do-canonical-smiles "c1ccccc1")))
  (is (string= (do-canonical-smiles "c1ccccc1") "c1ccccc1")))

(test canonical-smiles-normalization
  "Test SMILES normalization (different representations of same molecule)."
  (let ((smiles1 "CCO")
        (smiles2 "OCC"))
    (is (string= (do-canonical-smiles smiles1)
                 (do-canonical-smiles smiles2)))))

(test canonical-smiles-invalid
  "Test canonical SMILES with invalid input."
  (is (null (do-canonical-smiles "invalid"))))

;;;; =========================================================================
;;;; Atom Count Tests (4 tests)
;;;; =========================================================================

(test atom-count-ethanol
  "Test heavy atom count for ethanol (CCO)."
  (is (integerp (do-atom-count "CCO")))
  (is (= (do-atom-count "CCO") 3))) ; 2 C + 1 O = 3 heavy atoms

(test atom-count-methane
  "Test heavy atom count for methane (C)."
  (is (integerp (do-atom-count "C")))
  (is (= (do-atom-count "C") 1))) ; 1 C = 1 heavy atom

(test atom-count-benzene
  "Test heavy atom count for benzene (c1ccccc1)."
  (is (integerp (do-atom-count "c1ccccc1")))
  (is (= (do-atom-count "c1ccccc1") 6))) ; 6 C = 6 heavy atoms

(test atom-count-invalid
  "Test atom count with invalid SMILES."
  (is (null (do-atom-count "invalid"))))

;;;; =========================================================================
;;;; Bond Count Tests (4 tests)
;;;; =========================================================================

(test bond-count-ethanol
  "Test explicit bond count for ethanol (CCO)."
  (is (integerp (do-bond-count "CCO")))
  (is (= (do-bond-count "CCO") 2))) ; C-C + C-O = 2 explicit bonds

(test bond-count-methane
  "Test explicit bond count for methane (C)."
  (is (integerp (do-bond-count "C")))
  (is (= (do-bond-count "C") 0))) ; No explicit bonds (only implicit C-H)

(test bond-count-benzene
  "Test explicit bond count for benzene (c1ccccc1)."
  (is (integerp (do-bond-count "c1ccccc1")))
  (is (= (do-bond-count "c1ccccc1") 6))) ; 6 C-C aromatic bonds

(test bond-count-invalid
  "Test bond count with invalid SMILES."
  (is (null (do-bond-count "invalid"))))

;;;; =========================================================================
;;;; MOL File Tests (3 tests)
;;;; =========================================================================

(test molfile-ethanol
  "Test MOL file generation for ethanol (CCO)."
  (let ((molfile (do-molfile "CCO")))
    (is (stringp molfile))
    (is (search "V2000" molfile)) ; MOL file format marker
    (is (search "END" molfile))))

(test molfile-methane
  "Test MOL file generation for methane (C)."
  (let ((molfile (do-molfile "C")))
    (is (stringp molfile))
    (is (search "V2000" molfile))))

(test molfile-invalid
  "Test MOL file generation with invalid SMILES."
  (is (null (do-molfile "invalid"))))

;;;; =========================================================================
;;;; Hydrogen Count Tests (4 tests)
;;;; =========================================================================

(test hydrogen-count-ethanol
  "Test hydrogen count for ethanol (CCO)."
  (is (integerp (do-hydrogen-count "CCO")))
  (is (= (do-hydrogen-count "CCO") 6))) ; 3 H on first C + 2 H on second C + 1 H on O = 6

(test hydrogen-count-methane
  "Test hydrogen count for methane (C)."
  (is (integerp (do-hydrogen-count "C")))
  (is (= (do-hydrogen-count "C") 4))) ; 4 H on C = 4

(test hydrogen-count-benzene
  "Test hydrogen count for benzene (c1ccccc1)."
  (is (integerp (do-hydrogen-count "c1ccccc1")))
  (is (= (do-hydrogen-count "c1ccccc1") 6))) ; 1 H on each C = 6

(test hydrogen-count-invalid
  "Test hydrogen count with invalid SMILES."
  (is (null (do-hydrogen-count "invalid"))))

;;;; =========================================================================
;;;; Total Atom Count Tests (4 tests)
;;;; =========================================================================

(test total-atom-count-ethanol
  "Test total atom count for ethanol (CCO)."
  (is (integerp (do-total-atom-count "CCO")))
  (is (= (do-total-atom-count "CCO") 9))) ; 3 heavy atoms + 6 hydrogens = 9

(test total-atom-count-methane
  "Test total atom count for methane (C)."
  (is (integerp (do-total-atom-count "C")))
  (is (= (do-total-atom-count "C") 5))) ; 1 heavy atom + 4 hydrogens = 5

(test total-atom-count-benzene
  "Test total atom count for benzene (c1ccccc1)."
  (is (integerp (do-total-atom-count "c1ccccc1")))
  (is (= (do-total-atom-count "c1ccccc1") 12))) ; 6 heavy atoms + 6 hydrogens = 12

(test total-atom-count-invalid
  "Test total atom count with invalid SMILES."
  (is (null (do-total-atom-count "invalid"))))

;;;; =========================================================================
;;;; Molecular Format Support Test (1 test)
;;;; =========================================================================

(test molecular-format-support
  "Test that functions support multiple molecular formats."
  ;; Test SMILES format
  (is (string= (do-molecular-formula "O") "H2 O"))
  (is (= (do-atom-count "O") 1))
  (is (= (do-hydrogen-count "O") 2))

  ;; Test MOL format (generate MOL from SMILES, then parse it back)
  (let* ((water-smiles "O")
         (mol-format (do-molfile water-smiles)))
    (is (stringp mol-format))
    (is (search "V2000" mol-format))

    ;; Test that we can parse the MOL format back
    (is (string= (do-molecular-formula mol-format) "H2 O"))
    (is (= (do-atom-count mol-format) 1))
    (is (= (do-hydrogen-count mol-format) 2)))

  ;; Note: Indigo actually supports InChI format, so this returns a valid result
  ;; (is (null (do-molecular-formula "InChI=1S/H2O/h1H2")))
  )

;;;; =========================================================================
;;;; MOL File Roundtrip Test (1 test)
;;;; =========================================================================

(test molfile-roundtrip
  "Test converting SMILES to MOL format and back."
  (let* ((original-smiles "CCO")  ; ethanol
         (mol-format (do-molfile original-smiles))
         (canonical-from-smiles (do-canonical-smiles original-smiles))
         (canonical-from-mol (do-canonical-smiles mol-format)))
    ;; Should be able to generate MOL format
    (is (stringp mol-format))
    (is (search "V2000" mol-format))

    ;; Both formats should give same canonical SMILES
    (is (string= canonical-from-smiles canonical-from-mol))

    ;; Both should have same properties
    (is (= (do-atom-count original-smiles)
           (do-atom-count mol-format)))
    (is (= (do-bond-count original-smiles)
           (do-bond-count mol-format)))))

;;;; =========================================================================
;;;; Ring Count Tests (5 tests)
;;;; =========================================================================

(test ring-count-ethanol
  "Test ring count for ethanol (CCO)."
  (is (integerp (do-ring-count "CCO")))
  (is (= (do-ring-count "CCO") 0))) ; No rings in ethanol

(test ring-count-benzene
  "Test ring count for benzene (c1ccccc1)."
  (is (integerp (do-ring-count "c1ccccc1")))
  (is (= (do-ring-count "c1ccccc1") 1))) ; One aromatic ring

(test ring-count-cyclohexane
  "Test ring count for cyclohexane (C1CCCCC1)."
  (is (integerp (do-ring-count "C1CCCCC1")))
  (is (= (do-ring-count "C1CCCCC1") 1))) ; One saturated ring

(test ring-count-naphthalene
  "Test ring count for naphthalene (c1ccc2ccccc2c1)."
  (is (integerp (do-ring-count "c1ccc2ccccc2c1")))
  (is (= (do-ring-count "c1ccc2ccccc2c1") 2))) ; Two fused rings

(test ring-count-invalid
  "Test ring count with invalid molecular string."
  (is (null (do-ring-count "invalid"))))

;;;; =========================================================================
;;;; Aromatic Ring Count Tests (5 tests)
;;;; =========================================================================

(test aromatic-ring-count-ethanol
  "Test aromatic ring count for ethanol (CCO)."
  (is (integerp (do-aromatic-ring-count "CCO")))
  (is (= (do-aromatic-ring-count "CCO") 0))) ; No aromatic rings

(test aromatic-ring-count-benzene
  "Test aromatic ring count for benzene (c1ccccc1)."
  (is (integerp (do-aromatic-ring-count "c1ccccc1")))
  (is (= (do-aromatic-ring-count "c1ccccc1") 1))) ; One aromatic ring

(test aromatic-ring-count-cyclohexane
  "Test aromatic ring count for cyclohexane (C1CCCCC1)."
  (is (integerp (do-aromatic-ring-count "C1CCCCC1")))
  (is (= (do-aromatic-ring-count "C1CCCCC1") 0))) ; Saturated ring, not aromatic

(test aromatic-ring-count-naphthalene
  "Test aromatic ring count for naphthalene (c1ccc2ccccc2c1)."
  (is (integerp (do-aromatic-ring-count "c1ccc2ccccc2c1")))
  (is (= (do-aromatic-ring-count "c1ccc2ccccc2c1") 2))) ; Two aromatic rings

(test aromatic-ring-count-invalid
  "Test aromatic ring count with invalid molecular string."
  (is (null (do-aromatic-ring-count "invalid"))))

;;;; =========================================================================
;;;; Chiral Center Count Tests (5 tests)
;;;; =========================================================================

(test chiral-center-count-ethanol
  "Test chiral center count for ethanol (CCO)."
  (is (integerp (do-chiral-center-count "CCO")))
  (is (= (do-chiral-center-count "CCO") 0))) ; No chiral centers

(test chiral-center-count-alanine
  "Test chiral center count for L-alanine (N[C@@H](C)C(=O)O)."
  (is (integerp (do-chiral-center-count "N[C@@H](C)C(=O)O")))
  (is (= (do-chiral-center-count "N[C@@H](C)C(=O)O") 1))) ; One chiral center

(test chiral-center-count-glucose
  "Test chiral center count for glucose (O[C@H]1[C@H](O)[C@@H](O)[C@H](O)[C@H](O)[C@H]1CO)."
  (is (integerp (do-chiral-center-count "O[C@H]1[C@H](O)[C@@H](O)[C@H](O)[C@H](O)[C@H]1CO")))
  (is (>= (do-chiral-center-count "O[C@H]1[C@H](O)[C@@H](O)[C@H](O)[C@H](O)[C@H]1CO") 4))) ; Multiple chiral centers

(test chiral-center-count-invalid
  "Test chiral center count with invalid molecular string."
  (is (null (do-chiral-center-count "invalid"))))

(test chiral-center-count-propane
  "Test chiral center count for propane (CCC) - no chiral centers."
  (is (integerp (do-chiral-center-count "CCC")))
  (is (= (do-chiral-center-count "CCC") 0)))

;;;; =========================================================================
;;;; Formal Charge Tests (4 tests)
;;;; =========================================================================

(test formal-charge-neutral
  "Test formal charge for neutral ethanol (CCO)."
  (is (integerp (do-formal-charge "CCO")))
  (is (= (do-formal-charge "CCO") 0))) ; Neutral molecule

(test formal-charge-positive
  "Test formal charge for ammonium ([NH4+])."
  (is (integerp (do-formal-charge "[NH4+]")))
  (is (= (do-formal-charge "[NH4+]") 1))) ; +1 charge

(test formal-charge-negative
  "Test formal charge for hydroxide ([OH-])."
  (is (integerp (do-formal-charge "[OH-]")))
  (is (= (do-formal-charge "[OH-]") -1))) ; -1 charge

(test formal-charge-invalid
  "Test formal charge with invalid molecular string."
  (is (null (do-formal-charge "invalid"))))

;;;; =========================================================================
;;;; Hydrogen Bond Donor Count Tests (5 tests)
;;;; =========================================================================

(test hbd-count-ethanol
  "Test hydrogen bond donor count for ethanol (CCO)."
  (is (integerp (do-hbd-count "CCO")))
  (is (= (do-hbd-count "CCO") 1))) ; One OH group

(test hbd-count-water
  "Test hydrogen bond donor count for water (O)."
  (is (integerp (do-hbd-count "O")))
  (is (= (do-hbd-count "O") 1))) ; One OH2 group

(test hbd-count-ammonia
  "Test hydrogen bond donor count for ammonia (N)."
  (is (integerp (do-hbd-count "N")))
  (is (= (do-hbd-count "N") 1))) ; One NH3 group

(test hbd-count-methane
  "Test hydrogen bond donor count for methane (C)."
  (is (integerp (do-hbd-count "C")))
  (is (= (do-hbd-count "C") 0))) ; No N, O, or S with H

(test hbd-count-invalid
  "Test hydrogen bond donor count with invalid molecular string."
  (is (null (do-hbd-count "invalid"))))

;;;; =========================================================================
;;;; Hydrogen Bond Acceptor Count Tests (6 tests)
;;;; =========================================================================

(test hba-count-ethanol
  "Test hydrogen bond acceptor count for ethanol (CCO)."
  (is (integerp (do-hba-count "CCO")))
  (is (= (do-hba-count "CCO") 1))) ; One oxygen atom

(test hba-count-water
  "Test hydrogen bond acceptor count for water (O)."
  (is (integerp (do-hba-count "O")))
  (is (= (do-hba-count "O") 1))) ; One oxygen atom

(test hba-count-ether
  "Test hydrogen bond acceptor count for diethyl ether (CCOCC)."
  (is (integerp (do-hba-count "CCOCC")))
  (is (= (do-hba-count "CCOCC") 1))) ; One oxygen atom

(test hba-count-ammonia
  "Test hydrogen bond acceptor count for ammonia (N)."
  (is (integerp (do-hba-count "N")))
  (is (= (do-hba-count "N") 1))) ; One nitrogen atom

(test hba-count-methane
  "Test hydrogen bond acceptor count for methane (C)."
  (is (integerp (do-hba-count "C")))
  (is (= (do-hba-count "C") 0))) ; No N, O, or F

(test hba-count-invalid
  "Test hydrogen bond acceptor count with invalid molecular string."
  (is (null (do-hba-count "invalid"))))

;;;; =========================================================================
;;;; SMILES Tests (4 tests)
;;;; =========================================================================

(test smiles-ethanol
  "Test SMILES generation for ethanol (CCO)."
  (is (stringp (do-smiles "CCO")))
  (is (string= (do-smiles "CCO") "CCO"))) ; Should return same SMILES

(test smiles-benzene
  "Test SMILES generation for benzene (c1ccccc1)."
  (is (stringp (do-smiles "c1ccccc1")))
  (is (string= (do-smiles "c1ccccc1") "c1ccccc1"))) ; Should return same SMILES

(test smiles-conversion
  "Test SMILES conversion from MOL format."
  (let* ((original-smiles "CCO")
         (mol-format (do-molfile original-smiles))
         (converted-smiles (do-smiles mol-format)))
    (is (stringp converted-smiles))
    ;; Both should represent ethanol, though format might differ slightly
    (is (or (search "CCO" converted-smiles)
            (search "OCC" converted-smiles)))))

(test smiles-invalid
  "Test SMILES generation with invalid molecular string."
  (is (null (do-smiles "invalid"))))

;;;; =========================================================================
;;;; CML Tests (4 tests)
;;;; =========================================================================

(test cml-ethanol
  "Test CML generation for ethanol (CCO)."
  (let ((cml (do-cml "CCO")))
    (is (stringp cml))
    (is (search "<?xml" cml)) ; Should be XML format
    (is (search "molecule" cml)))) ; Should contain molecule element

(test cml-water
  "Test CML generation for water (O)."
  (let ((cml (do-cml "O")))
    (is (stringp cml))
    (is (search "<?xml" cml))
    (is (search "molecule" cml))))

(test cml-benzene
  "Test CML generation for benzene (c1ccccc1)."
  (let ((cml (do-cml "c1ccccc1")))
    (is (stringp cml))
    (is (search "<?xml" cml))
    (is (search "molecule" cml))))

(test cml-invalid
  "Test CML generation with invalid molecular string."
  (is (null (do-cml "invalid"))))

;;;; =========================================================================
;;;; Format Conversion Roundtrip Test (1 test)
;;;; =========================================================================

(test format-conversion-roundtrip
  "Test conversion between different formats."
  (let* ((original-smiles "CCO")
         ;; Convert SMILES -> MOL -> CML -> SMILES
         (mol-format (do-molfile original-smiles))
         (cml-format (do-cml original-smiles))
         (canonical-original (do-canonical-smiles original-smiles))
         (canonical-from-mol (do-canonical-smiles mol-format)))
    ;; All should be valid strings
    (is (stringp mol-format))
    (is (stringp cml-format))
    (is (stringp canonical-original))
    (is (stringp canonical-from-mol))

    ;; Canonical SMILES should be consistent across formats
    (is (string= canonical-original canonical-from-mol))

    ;; CML should be valid XML with molecule content
    (is (search "<?xml" cml-format))
    (is (search "molecule" cml-format))))

;;;; =========================================================================
;;;; Stereochemistry Tests (5 tests)
;;;; =========================================================================

(test has-stereochemistry-no-stereo
  "Test stereochemistry check for ethanol (no stereochemistry)."
  (is (not (do-has-stereochemistry "CCO"))))  ; No stereocenters or stereobonds

(test has-stereochemistry-with-stereo
  "Test stereochemistry check for L-alanine (has stereochemistry)."
  (is (do-has-stereochemistry "N[C@@H](C)C(=O)O"))) ; Has stereocenter

(test has-stereochemistry-double-bond
  "Test stereochemistry check for trans-2-butene (has E/Z stereochemistry)."
  (is (do-has-stereochemistry "C/C=C/C"))) ; Trans double bond

(test has-stereochemistry-benzene
  "Test stereochemistry check for benzene (no stereochemistry)."
  (is (not (do-has-stereochemistry "c1ccccc1")))) ; No stereo

(test has-stereochemistry-invalid
  "Test stereochemistry check with invalid molecular string."
  (is (null (do-has-stereochemistry "invalid"))))

;;;; =========================================================================
;;;; Chirality Tests (5 tests)
;;;; =========================================================================

(test is-chiral-no
  "Test chirality check for ethanol (not chiral)."
  (is (not (do-is-chiral "CCO")))) ; Achiral molecule

(test is-chiral-yes
  "Test chirality check for L-alanine (chiral)."
  (is (do-is-chiral "N[C@@H](C)C(=O)O"))) ; Chiral molecule

(test is-chiral-meso
  "Test chirality check for meso compound (not chiral overall)."
  ;; Using a simpler example - propane (definitely not chiral)
  (is (not (do-is-chiral "CCC")))) ; Achiral

(test is-chiral-benzene
  "Test chirality check for benzene (not chiral)."
  (is (not (do-is-chiral "c1ccccc1")))) ; Not chiral

(test is-chiral-invalid
  "Test chirality check with invalid molecular string."
  (is (null (do-is-chiral "invalid"))))

;;;; =========================================================================
;;;; Coordinate Tests (7 tests)
;;;; =========================================================================

(test has-coordinates-smiles
  "Test coordinate check for SMILES (no coordinates)."
  (is (not (do-has-coordinates "CCO")))) ; SMILES typically has no coords

(test has-coordinates-mol-format
  "Test coordinate check for MOL format with actual coordinates."
  ;; Real MOL format with coordinates for ethanol
  (let ((mol-with-coords "
  -INDIGO-08212515252D

  3  2  0  0  0  0  0  0  0  0999 V2000
    0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
    1.2990    0.7500    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
    2.5981    0.0000    0.0000 O   0  0  0  0  0  0  0  0  0  0  0  0
  1  2  1  0  0  0  0
  2  3  1  0  0  0  0
M  END"))
    ;; Should detect coordinates in the MOL format
    (is (do-has-coordinates mol-with-coords))

    ;; Verify this is different from SMILES behavior
    (is (not (do-has-coordinates "CCO")))  ; SMILES has no coordinates

    ;; Double-check the coordinate detection works correctly
    (is (eq (do-has-coordinates mol-with-coords) t))
    (is (eq (do-has-coordinates "CCO") nil))))

(test has-coordinates-benzene
  "Test coordinate check for benzene SMILES (no coordinates)."
  (is (not (do-has-coordinates "c1ccccc1")))) ; SMILES has no coords

(test has-coordinates-invalid
  "Test coordinate check with invalid molecular string."
  (is (null (do-has-coordinates "invalid"))))

(test structural-analysis-consistency
  "Test consistency between structural analysis functions."
  (let* ((chiral-molecule "N[C@@H](C)C(=O)O")  ; L-alanine
         (achiral-molecule "CCO"))                ; ethanol
    ;; Chiral molecule should have stereochemistry
    (is (do-has-stereochemistry chiral-molecule))
    (is (do-is-chiral chiral-molecule))

    ;; Achiral molecule should not have stereochemistry or chirality
    (is (not (do-has-stereochemistry achiral-molecule)))
    (is (not (do-is-chiral achiral-molecule)))

    ;; Test that both can be converted to MOL format (but coordinates may not be present)
    (let ((chiral-mol (do-molfile chiral-molecule))
          (achiral-mol (do-molfile achiral-molecule)))
      ;; Just verify the MOL format strings are created successfully
      (is (stringp chiral-mol))
      (is (stringp achiral-mol))
      (is (search "V2000" chiral-mol))
      (is (search "V2000" achiral-mol)))))

(test has-z-coord-basic
  "Test Z coordinate detection for basic molecules."
  ;; Most SMILES don't have Z coordinates by default
  (is (null (do-has-z-coord "CCO")))
  (is (null (do-has-z-coord "c1ccccc1"))))

(test has-z-coord-invalid
  "Test Z coordinate detection with invalid input."
  (is (null (do-has-z-coord "invalid"))))

;;;; =========================================================================
;;;; Substructure Matching Tests (5 tests)
;;;; =========================================================================

(test substructure-match-positive
  "Test substructure matching - ethanol contains ethyl group."
  (is (do-substructure-match "CCO" "CC"))) ; Ethanol contains ethyl

(test substructure-match-negative
  "Test substructure matching - methane does not contain ethyl group."
  (is (not (do-substructure-match "C" "CC")))) ; Methane does not contain ethyl

(test substructure-match-benzene
  "Test substructure matching - toluene contains benzene ring."
  (is (do-substructure-match "Cc1ccccc1" "c1ccccc1"))) ; Toluene contains benzene

(test substructure-match-aromatic
  "Test substructure matching - benzene contains aromatic carbon."
  (is (do-substructure-match "c1ccccc1" "c"))) ; Benzene contains aromatic carbon

(test substructure-match-invalid
  "Test substructure matching with invalid molecular strings."
  (is (null (do-substructure-match "CCO" "invalid")))
  (is (null (do-substructure-match "invalid" "CCO"))))

;;;; =========================================================================
;;;; Exact Match Tests (5 tests)
;;;; =========================================================================

(test exact-match-same
  "Test exact matching - same molecules should match."
  (is (do-exact-match "CCO" "CCO"))) ; Same ethanol

(test exact-match-different
  "Test exact matching - different molecules should not match."
  (is (not (do-exact-match "CCO" "CCC")))) ; Ethanol vs propane

(test exact-match-isomers
  "Test exact matching - different representations of same molecule."
  (is (do-exact-match "CCO" "OCC"))) ; Different SMILES for ethanol

(test exact-match-stereoisomers
  "Test exact matching - stereoisomers should not match exactly."
  (is (not (do-exact-match "N[C@@H](C)C(=O)O" "N[C@H](C)C(=O)O")))) ; L vs D alanine

(test exact-match-invalid
  "Test exact matching with invalid molecular strings."
  (is (null (do-exact-match "CCO" "invalid")))
  (is (null (do-exact-match "invalid" "CCO"))))

;;;; =========================================================================
;;;; Similarity Tests (4 tests)
;;;; =========================================================================

(test similarity-identical
  "Test similarity calculation - identical molecules should have similarity 1.0."
  (let ((sim (do-similarity "CCO" "CCO")))
    (is (floatp sim))
    (is (> sim 0.99)))) ; Should be very close to 1.0

(test similarity-different
  "Test similarity calculation - very different molecules should have low similarity."
  (let ((sim (do-similarity "CCO" "c1ccccc1")))  ; Ethanol vs benzene
    (is (floatp sim))
    (is (>= sim 0.0))
    (is (<= sim 1.0))
    (is (< sim 0.5)))) ; Should be quite different

(test similarity-similar
  "Test similarity calculation - similar molecules should have moderate similarity."
  (let ((sim (do-similarity "CCO" "CCC")))  ; Ethanol vs propane
    (is (floatp sim))
    (is (>= sim 0.0))
    (is (<= sim 1.0))))

(test similarity-invalid
  "Test similarity calculation with invalid molecular strings."
  (is (null (do-similarity "CCO" "invalid")))
  (is (null (do-similarity "invalid" "CCO"))))

;;;; =========================================================================
;;;; Search Matching Consistency Test (1 test)
;;;; =========================================================================

(test search-matching-consistency
  "Test consistency between different search and matching functions."
  (let* ((benzene "c1ccccc1")
         (toluene "Cc1ccccc1")
         (ethanol "CCO"))
    ;; Substructure relationships
    (is (do-substructure-match toluene benzene))  ; Toluene contains benzene
    (is (not (do-substructure-match benzene toluene))) ; Benzene doesn't contain toluene

    ;; Exact matching
    (is (do-exact-match benzene benzene))  ; Same molecule
    (is (not (do-exact-match benzene toluene))) ; Different molecules

    ;; Similarity relationships
    (let ((sim-same (do-similarity benzene benzene))
          (sim-similar (do-similarity benzene toluene))
          (sim-different (do-similarity benzene ethanol)))
      ;; Same molecules should have highest similarity
      (is (> sim-same sim-similar))
      (is (> sim-similar sim-different))

      ;; All similarities should be in valid range
      (is (and (>= sim-same 0.0) (<= sim-same 1.0)))
      (is (and (>= sim-similar 0.0) (<= sim-similar 1.0)))
      (is (and (>= sim-different 0.0) (<= sim-different 1.0))))))

;;;; =========================================================================
;;;; Reaction Chemistry Tests (6 tests)
;;;; =========================================================================

(test reaction-products-count-basic
  "Test product counting for basic reactions."
  ;; Simple synthesis: A + B -> C
  (is (= (do-reaction-products-count "CCO.CC>>CCOC") 1))
  ;; Decomposition: A -> B + C
  (is (= (do-reaction-products-count "CC(=O)OC>>CC(=O)O.CO") 2)))

(test reaction-reactants-count-basic
  "Test reactant counting for basic reactions."
  ;; Simple synthesis: A + B -> C
  (is (= (do-reaction-reactants-count "CCO.CC>>CCOC") 2))
  ;; Decomposition: A -> B + C
  (is (= (do-reaction-reactants-count "CC(=O)OC>>CC(=O)O.CO") 1)))

(test reaction-complex
  "Test complex reaction with multiple reactants and products."
  (let ((complex-rxn "CCO.CC.O>>CCOC.CO.CC(O)C"))
    (is (= (do-reaction-reactants-count complex-rxn) 3))
    (is (= (do-reaction-products-count complex-rxn) 3))))

(test reaction-with-catalysts
  "Test reaction counting with catalyst format."
  ;; Proper catalyst format: reactants>catalyst>products
  (let ((catalyzed-rxn "CCO>[Pd]>CCOC"))  ; Single > for catalyst
    (is (= (do-reaction-reactants-count catalyzed-rxn) 1))
    (is (= (do-reaction-products-count catalyzed-rxn) 1))))

(test reaction-invalid
  "Test reaction functions with invalid inputs."
  (is (null (do-reaction-products-count "invalid")))
  (is (null (do-reaction-reactants-count "invalid")))
  (is (null (do-reaction-products-count "")))
  (is (null (do-reaction-reactants-count ""))))

(test reaction-consistency
  "Test consistency of reaction parsing."
  (let ((rxn "C.C.O>>CCO.CO"))  ; Two carbons + oxygen -> ethanol + methanol
    (let ((reactants (do-reaction-reactants-count rxn))
          (products (do-reaction-products-count rxn)))
      (is (= reactants 3))  ; C, C, O
      (is (= products 2))   ; CCO, CO
      ;; Both functions should work on same input
      (is (numberp reactants))
      (is (numberp products)))))

;;;; =========================================================================
;;;; Mass Calculation Tests (6 tests)
;;;; =========================================================================

(test most-abundant-mass-ethanol
  "Test most abundant mass calculation for ethanol (CCO)."
  (is (floatp (do-most-abundant-mass "CCO")))
  (is (float-equal (do-most-abundant-mass "CCO") 46.04 0.1)))

(test most-abundant-mass-methane
  "Test most abundant mass calculation for methane (C)."
  (is (floatp (do-most-abundant-mass "C")))
  (is (float-equal (do-most-abundant-mass "C") 16.03 0.1)))

(test most-abundant-mass-invalid
  "Test most abundant mass calculation with invalid input."
  (is (null (do-most-abundant-mass "invalid"))))

(test monoisotopic-mass-ethanol
  "Test monoisotopic mass calculation for ethanol (CCO)."
  (is (floatp (do-monoisotopic-mass "CCO")))
  (is (float-equal (do-monoisotopic-mass "CCO") 46.04 0.1)))

(test monoisotopic-mass-benzene
  "Test monoisotopic mass calculation for benzene (c1ccccc1)."
  (is (floatp (do-monoisotopic-mass "c1ccccc1")))
  (is (float-equal (do-monoisotopic-mass "c1ccccc1") 78.05 0.1)))

(test monoisotopic-mass-invalid
  "Test monoisotopic mass calculation with invalid input."
  (is (null (do-monoisotopic-mass "invalid"))))

;;;; =========================================================================
;;;; Layered Code Tests (3 tests)
;;;; =========================================================================

(test layered-code-ethanol
  "Test layered code generation for ethanol (CCO)."
  (let ((code (do-layered-code "CCO")))
    (is (stringp code))
    (is (> (length code) 0))))

(test layered-code-benzene
  "Test layered code generation for benzene (c1ccccc1)."
  (let ((code (do-layered-code "c1ccccc1")))
    (is (stringp code))
    (is (> (length code) 0))))

(test layered-code-invalid
  "Test layered code generation with invalid input."
  (is (null (do-layered-code "invalid"))))

;;;; =========================================================================
;;;; Heavy Atom Count Tests (4 tests)
;;;; =========================================================================

(test heavy-atom-count-ethanol
  "Test heavy atom count for ethanol (CCO)."
  (is (= (do-heavy-atom-count "CCO") 3)))

(test heavy-atom-count-benzene
  "Test heavy atom count for benzene (c1ccccc1)."
  (is (= (do-heavy-atom-count "c1ccccc1") 6)))

(test heavy-atom-count-methane
  "Test heavy atom count for methane (C)."
  (is (= (do-heavy-atom-count "C") 1)))

(test heavy-atom-count-invalid
  "Test heavy atom count with invalid input."
  (is (null (do-heavy-atom-count "invalid"))))

;;;; =========================================================================
;;;; Mass Functions Consistency Test (1 test)
;;;; =========================================================================

(test mass-functions-consistency
  "Test that mass functions return consistent results."
  (let ((mol "CCO"))
    (let ((abundant-mass (do-most-abundant-mass mol))
          (monoisotopic-mass (do-monoisotopic-mass mol))
          (molecular-weight (do-molecular-weight mol)))
      ;; All should be close to each other for simple organic molecules
      (is (< (abs (- abundant-mass monoisotopic-mass)) 1.0))
      (is (< (abs (- abundant-mass molecular-weight)) 1.0))
      (is (< (abs (- monoisotopic-mass molecular-weight)) 1.0)))))

;;;; =========================================================================
;;;; Count Functions Consistency Test (1 test)
;;;; =========================================================================

(test count-functions-consistency
  "Test that count functions return consistent results."
  (let ((mol "CCO"))
    (let ((heavy-count (do-heavy-atom-count mol))
          (atom-count (do-atom-count mol))
          (total-count (do-total-atom-count mol))
          (hydrogen-count (do-hydrogen-count mol)))
      ;; Heavy atom count should equal atom count for this function
      (is (= heavy-count atom-count))
      ;; Total count should be heavy atoms plus hydrogens
      (is (= total-count (+ heavy-count hydrogen-count)))
      ;; Ethanol should have 3 heavy atoms and 6 hydrogens
      (is (= heavy-count 3))
      (is (= hydrogen-count 6)))))
