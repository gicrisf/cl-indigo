;;;; test-readme-examples.lisp - Tests for all README.md examples

(in-package #:cl-indigo-tests)

(def-suite readme-tests
  :description "Tests for README.md documentation examples"
  :in :cl-indigo-tests)

(in-suite readme-tests)

;;;; =========================================================================
;;;; Basic Examples - Stateless Functions
;;;; =========================================================================

(test readme-molecular-weight
  "Test molecular weight calculation."
  (let ((result (do-molecular-weight "CCO")))
    (is (floatp result))
    (is (float-equal result 46.069 0.01))))

(test readme-molecular-formula
  "Test molecular formula generation."
  (let ((result (do-molecular-formula "CCO")))
    (is (stringp result))
    (is-true (search "C2" result))
    (is-true (search "H6" result))
    (is-true (search "O" result))))

(test readme-canonical-smiles
  "Test canonical SMILES generation."
  (let ((result (do-canonical-smiles "CCO")))
    (is (stringp result))
    (is-true (or (string= "CCO" result)
                 (string= "OCC" result)))))

(test readme-atom-count
  "Test heavy atom count."
  (let ((result (do-atom-count "c1ccccc1")))
    (is (integerp result))
    (is (= result 6))))

(test readme-ring-count
  "Test ring count."
  (let ((result (do-ring-count "c1ccccc1")))
    (is (integerp result))
    (is (= result 1))))

(test readme-substructure-match
  "Test substructure matching."
  (let ((result (do-substructure-match "CCO" "CO")))
    (is (eq result t))))

(test readme-exact-match
  "Test exact matching."
  (let ((result (do-exact-match "CCO" "OCC")))
    (is (eq result t))))

(test readme-reaction-reactants-count
  "Test reaction reactants count."
  (let ((result (do-reaction-reactants-count "CCO.CC>>CCOC")))
    (is (integerp result))
    (is (= result 2))))

;;;; =========================================================================
;;;; Advanced Examples
;;;; =========================================================================

(test readme-advanced-example
  "Test with-molecule and iterator usage from README."
  (let ((result
         (with-molecule (mol "c1ccccc1")  ; Benzene
           (with-atoms-iterator (atoms mol)
             ;; Collect all atom symbols
             (indigo-map #'atom-symbol atoms)))))
    (is (listp result))
    (is (= (length result) 6))
    (is (equal result '("C" "C" "C" "C" "C" "C")))))

(test readme-molecular-weights-example
  "Test comparing molecular weights of multiple molecules."
  (let ((result
         (with-molecule* ((ethanol "CCO")
                          (benzene "c1ccccc1")
                          (propane "CCC"))
           (list (molecular-weight ethanol)
                 (molecular-weight benzene)
                 (molecular-weight propane)))))
    (is (listp result))
    (is (= (length result) 3))
    (is (float-equal (nth 0 result) 46.069 0.01))
    (is (float-equal (nth 1 result) 78.114 0.01))
    (is (float-equal (nth 2 result) 44.097 0.01))))

(test readme-with-macros-example
  "Test comparing molecules using with- macros."
  (let ((result
         (with-molecule* ((mol1 "CCO")       ; Ethanol
                          (mol2 "CC(O)C"))    ; Isopropanol
           (with-fingerprint* ((fp1 mol1 "sim")
                               (fp2 mol2 "sim"))
             (similarity fp1 fp2 :tanimoto)))))
    (is (floatp result))
    (is (>= result 0.0))
    (is (<= result 1.0))
    ;; Should be around 0.71 for these molecules
    (is (> result 0.7))
    (is (< result 0.72))))

;;;; =========================================================================
;;;; Reaction Examples
;;;; =========================================================================

(test readme-reaction-example
  "Test reaction iteration from README."
  (let ((result
         (with-reaction (rxn "CCO.CC(=O)O>>CCOC(=O)C")  ; Esterification
           (with-reactants-iterator (reactants rxn)
             (with-products-iterator (products rxn)
               (list :reactant-count
                     (length (indigo-map #'canonical-smiles reactants))
                     :product-count
                     (length (indigo-map #'canonical-smiles products))))))))
    (is (listp result))
    (is (= (getf result :reactant-count) 2))
    (is (= (getf result :product-count) 1))))

;;;; =========================================================================
;;;; Rendering Examples
;;;; =========================================================================

(test readme-rendering-example
  "Test rendering to SVG file."
  (with-temp-file (temp-file "benzene" ".svg")
    (with-molecule (mol "c1ccccc1")
      (set-option "render-output-format" "svg")
      (set-option-int "render-image-width" 300)
      (set-option-int "render-image-height" 300)
      (render-to-file mol temp-file))
    ;; Verify the file was created
    (is-true (probe-file temp-file))
    ;; Verify it contains SVG content
    (let ((content (read-file-contents temp-file)))
      (is-true (search "<svg" content)))))

;;;; =========================================================================
;;;; All Examples in One Test (Integration Test)
;;;; =========================================================================

(test readme-all-basic-examples-together
  "Test all basic examples in a single integration test."
  (let ((results nil))
    ;; Collect all results
    (push (cons 'molecular-weight (do-molecular-weight "CCO")) results)
    (push (cons 'molecular-formula (do-molecular-formula "CCO")) results)
    (push (cons 'canonical-smiles (do-canonical-smiles "CCO")) results)
    (push (cons 'atom-count (do-atom-count "c1ccccc1")) results)
    (push (cons 'ring-count (do-ring-count "c1ccccc1")) results)
    (push (cons 'substructure-match (do-substructure-match "CCO" "[OH]")) results)
    (push (cons 'exact-match (do-exact-match "CCO" "OCC")) results)
    (push (cons 'reaction-reactants-count
                (do-reaction-reactants-count "CCO.CC>>CCOC")) results)

    ;; Verify all succeeded
    (is (= (length results) 8))
    (is (floatp (cdr (assoc 'molecular-weight results))))
    (is (stringp (cdr (assoc 'molecular-formula results))))
    (is (stringp (cdr (assoc 'canonical-smiles results))))
    (is (integerp (cdr (assoc 'atom-count results))))
    (is (integerp (cdr (assoc 'ring-count results))))
    (is (eq (cdr (assoc 'substructure-match results)) t))
    (is (eq (cdr (assoc 'exact-match results)) t))
    (is (integerp (cdr (assoc 'reaction-reactants-count results))))))
