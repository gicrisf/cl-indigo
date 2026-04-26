;;;; test-react.lisp - Tests for reaction operations

(in-package #:cl-indigo-tests)

(def-suite react-tests
  :description "Tests for reaction operations"
  :in :cl-indigo-tests)

(in-suite react-tests)

;;;; =========================================================================
;;;; With-Reaction Macro Tests
;;;; =========================================================================

(test with-reaction-basic
  "Test indigo-with-reaction macro."
  (with-reaction (rxn "CC>>CCO")
    (is (integerp rxn))
    (is (> rxn 0))
    ;; Verify it's a valid reaction by iterating reactants
    (with-reactants-iterator (reactants rxn)
      (is (integerp reactants))
      (is (> reactants 0)))))

(test with-reaction-complex
  "Test indigo-with-reaction with complex reaction."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (is (integerp rxn))
    (is (> rxn 0))
    ;; Count reactants manually
    (let ((reactant-count 0))
      (with-reactants-iterator (reactants rxn)
        (loop for reactant = (indigo-next reactants)
              while (and reactant (> reactant 0))
              do (incf reactant-count)))
      (is (= reactant-count 2)))
    ;; Count products manually
    (let ((product-count 0))
      (with-products-iterator (products rxn)
        (loop for product = (indigo-next products)
              while (and product (> product 0))
              do (incf product-count)))
      (is (= product-count 1)))))

(test with-reaction-workflow
  "Test reaction workflow with with-* macros."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (let ((reactant-count 0)
          (product-count 0))
      (with-reactants-iterator (reactants rxn)
        (loop for reactant = (indigo-next reactants)
              while (and reactant (> reactant 0))
              do (incf reactant-count)))
      (with-products-iterator (products rxn)
        (loop for product = (indigo-next products)
              while (and product (> product 0))
              do (incf product-count)))
      (is (= reactant-count 2))
      (is (= product-count 1)))))

;;;; =========================================================================
;;;; Reaction Loading Tests
;;;; =========================================================================

(test load-reaction-from-string
  "Test loading reaction from string."
  (let ((rxn (load-reaction-from-string "C.C>>CC")))
    (is (integerp rxn))
    (is (> rxn 0))
    (indigo-free rxn)))

(test load-reaction-invalid
  "Test loading invalid reaction."
  (signals indigo-error
    (load-reaction-from-string "INVALID>>REACTION")))

;;;; =========================================================================
;;;; Reaction Iterator Tests
;;;; =========================================================================

(test iterate-reactants
  "Test iterating over reactants."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (with-reactants-iterator (reactants rxn)
      (let ((count 0))
        (loop for reactant = (indigo-next reactants)
              while (and reactant (> reactant 0))
              do (incf count))
        (is (= count 2))))))

(test iterate-products
  "Test iterating over products."
  (with-reaction (rxn "CCO.CC>>CCOC.O")
    (with-products-iterator (products rxn)
      (let ((count 0))
        (loop for product = (indigo-next products)
              while (and product (> product 0))
              do (incf count))
        (is (= count 2))))))

;;;; =========================================================================
;;;; Reaction Cleanup Tests
;;;; =========================================================================

(test reaction-cleanup
  "Test reaction resource cleanup."
  (with-reference-check
    (with-reaction (rxn "CC>>C.C")
      (is (integerp rxn))
      (is (> rxn 0)))))

;;;; =========================================================================
;;;; Automap Tests
;;;; =========================================================================

(test automap-basic
  "Test automatic atom mapping."
  (with-reaction (rxn "CC>>C.C")
    (is (integerp (automap rxn "discard")))))

(test automap-modes
  "Test different automap modes."
  (with-reaction (rxn "CC>>C.C")
    (is (integerp (automap rxn "discard")))
    (is (integerp (automap rxn "keep")))
    (is (integerp (automap rxn "alter")))
    (is (integerp (automap rxn "clear")))))

;;;; =========================================================================
;;;; Atom Mapping Number Tests
;;;; =========================================================================

(test atom-mapping-number
  "Test get/set atom mapping numbers."
  (with-reaction (rxn "CC>>C.C")
    ;; First automap the reaction
    (automap rxn "discard")
    ;; Get a reactant molecule and its first atom
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (when mol
          (with-atoms-iterator (atoms mol)
            (let ((atom (indigo-next atoms)))
              (when atom
                ;; Should have a mapping number after automap
                (let ((mapping (get-atom-mapping-number rxn atom)))
                  (is (integerp mapping)))))))))))

(test set-atom-mapping-number
  "Test setting atom mapping numbers."
  (with-reaction (rxn "CC>>C.C")
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (when mol
          (with-atoms-iterator (atoms mol)
            (let ((atom (indigo-next atoms)))
              (when atom
                (is (>= (set-atom-mapping-number rxn atom 42) 0))
                (is (= (get-atom-mapping-number rxn atom) 42))))))))))

;;;; =========================================================================
;;;; Clear AAM Tests
;;;; =========================================================================

(test clear-aam-basic
  "Test clearing atom-to-atom mapping."
  (with-reaction (rxn "[CH3:1][CH3:2]>>[CH4:1].[CH4:2]")
    (is (>= (clear-aam rxn) 0))
    ;; After clearing, mapping numbers should be 0
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (when mol
          (with-atoms-iterator (atoms mol)
            (let ((atom (indigo-next atoms)))
              (when atom
                (is (= (get-atom-mapping-number rxn atom) 0))))))))))

;;;; =========================================================================
;;;; Correct Reacting Centers Tests
;;;; =========================================================================

(test correct-reacting-centers-basic
  "Test correcting reacting centers."
  (with-reaction (rxn "CC>>C.C")
    (automap rxn "discard")
    (is (>= (correct-reacting-centers rxn) 0))))

;;;; =========================================================================
;;;; Reacting Center Tests
;;;; =========================================================================

(test get-reacting-center
  "Test getting reacting center type."
  (with-reaction (rxn "CC>>C.C")
    (automap rxn "discard")
    (correct-reacting-centers rxn)
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (when mol
          (with-bonds-iterator (bonds mol)
            (let ((bond (indigo-next bonds)))
              (when bond
                (let ((rc (get-reacting-center rxn bond)))
                  (is (integerp rc)))))))))))

(test set-reacting-center
  "Test setting reacting center type."
  (with-reaction (rxn "CC>>C.C")
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (when mol
          (with-bonds-iterator (bonds mol)
            (let ((bond (indigo-next bonds)))
              (when bond
                ;; Set to RC_MADE_OR_BROKEN (4)
                (is (>= (set-reacting-center rxn bond 4) 0))
                (is (= (get-reacting-center rxn bond) 4))))))))))

;;;; =========================================================================
;;;; Count Reactants/Products Tests
;;;; =========================================================================

(test count-reactants-basic
  "Test counting reactants."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (is (= (count-reactants rxn) 2))))

(test count-products-basic
  "Test counting products."
  (with-reaction (rxn "CC>>C.C")
    (is (= (count-products rxn) 2))))

(test count-reactants-single
  "Test counting single reactant."
  (with-reaction (rxn "CC>>C.C")
    (is (= (count-reactants rxn) 1))))

(test count-products-single
  "Test counting single product."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (is (= (count-products rxn) 1))))
