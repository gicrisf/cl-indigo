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
