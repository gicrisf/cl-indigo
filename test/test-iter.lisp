;;;; test-iter.lisp - Iterator tests

(in-package #:cl-indigo-tests)

(def-suite iter-tests
  :description "Tests for iterator operations"
  :in :cl-indigo-tests)

(in-suite iter-tests)

;;;; =========================================================================
;;;; Basic Iterator Tests
;;;; =========================================================================

(test atoms-iterator
  "Test iterating over atoms."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let ((count 0))
        (loop for atom = (indigo-next atoms)
              while atom
              do (progn
                   (incf count)
                   (indigo-free atom)))
        (is (= 3 count))))))

(test bonds-iterator
  "Test iterating over bonds."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds mol)
      (let ((count 0))
        (loop for bond = (indigo-next bonds)
              while bond
              do (progn
                   (incf count)
                   (indigo-free bond)))
        (is (= 2 count))))))

(test neighbors-iterator
  "Test neighbor iteration functionality."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms-iter mol)
      (let ((first-atom (indigo-next atoms-iter)))
        (is-true first-atom)
        (with-neighbors-iterator (neighbors-iter first-atom)
          (let ((count 0))
            (loop for neighbor = (indigo-next neighbors-iter)
                  while neighbor
                  do (progn
                       (incf count)
                       (indigo-free neighbor)))
            ;; First carbon in CCO has 1 neighbor (the other carbon)
            (is (= count 1))))
        (indigo-free first-atom)))))

(test components-iterator
  "Test connected components iteration."
  (with-molecule (mol "CCO.CC")  ; Two components
    (with-components-iterator (components mol)
      (let ((count 0))
        (loop for component = (indigo-next components)
              while component
              do (progn
                   (incf count)
                   (indigo-free component)))
        (is (= count 2))))))

(test sssr-iterator
  "Test SSSR ring iteration."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-sssr-iterator (rings mol)
      (let ((count 0))
        (loop for ring = (indigo-next rings)
              while ring
              do (progn
                   (incf count)
                   (indigo-free ring)))
        (is (= count 1))))))

;;;; =========================================================================
;;;; indigo-map Tests
;;;; =========================================================================

(test indigo-map-symbols
  "Test indigo-map with atom symbols."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let ((symbols (indigo-map #'atom-symbol atoms)))
        (is (equal '("C" "C" "O") symbols))))))

(test indigo-map-bond-orders
  "Test indigo-map with bond orders."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds mol)
      (let ((orders (indigo-map #'bond-order bonds)))
        (is (equal '(:single :single) orders))))))

;;;; =========================================================================
;;;; Iterator Error Handling Tests
;;;; =========================================================================

(test iterator-error-handling
  "Test iterator error handling with invalid inputs."
  ;; Test with invalid molecule handle - should signal errors
  (signals indigo-error (iterate-atoms -1))
  (signals indigo-error (iterate-bonds -1))
  (signals indigo-error (iterate-sssr -1))

  ;; Test next with invalid iterator - returns nil (exhausted state)
  (is (null (indigo-next -1)))

  ;; Test with valid molecule (error-free path)
  (with-molecule (mol "CCO")
    (is (integerp (iterate-sssr mol)))
    (is (integerp (iterate-stereocenters mol)))))

(test iterator-empty-results
  "Test iterators with molecules that have no items to iterate."
  (with-molecule (mol "C")  ; Single carbon
    ;; Single carbon has no rings
    (let ((iter (iterate-sssr mol)))
      (is (integerp iter))
      (is (null (indigo-next iter)))  ; No rings to iterate
      (indigo-free iter))

    ;; Single carbon has no stereocenters
    (let ((iter (iterate-stereocenters mol)))
      (is (integerp iter))
      (is (null (indigo-next iter)))  ; No stereocenters
      (indigo-free iter))))

;;;; =========================================================================
;;;; Iterator Memory Management Tests
;;;; =========================================================================

(test iterator-memory-management
  "Test proper memory management with iterators."
  (with-molecule (mol "c1ccccc1c2ccccc2")  ; Biphenyl
    ;; Create multiple iterators
    (let ((atoms-iter (iterate-atoms mol))
          (bonds-iter (iterate-bonds mol))
          (rings-iter (iterate-sssr mol)))

      ;; All should be valid
      (is (integerp atoms-iter))
      (is (integerp bonds-iter))
      (is (integerp rings-iter))

      ;; Use iterators partially
      (let ((atom (indigo-next atoms-iter))
            (bond (indigo-next bonds-iter))
            (ring (indigo-next rings-iter)))
        (is-true atom)
        (is-true bond)
        (is-true ring)
        ;; Free the items we got
        (when atom (indigo-free atom))
        (when bond (indigo-free bond))
        (when ring (indigo-free ring)))

      ;; Free iterators
      (indigo-free atoms-iter)
      (indigo-free bonds-iter)
      (indigo-free rings-iter))))

(test iterator-cleanup
  "Test that iterators are properly cleaned up."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        (indigo-map #'atom-symbol atoms)))))

;;;; =========================================================================
;;;; With-style Iterator Macro Tests
;;;; =========================================================================

(test with-atoms
  "Test with-atoms-iterator macro."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (is (integerp atoms))
      (is (> atoms 0))
      (let ((count 0))
        (loop while (indigo-next atoms)
              do (incf count))
        (is (= count 3))))))

(test with-bonds
  "Test with-bonds-iterator macro."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds mol)
      (is (integerp bonds))
      (is (> bonds 0))
      (let ((count 0))
        (loop while (indigo-next bonds)
              do (incf count))
        (is (= count 2))))))

(test with-neighbors
  "Test with-neighbors-iterator macro."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let ((first-atom (indigo-next atoms)))
        (when first-atom
          (with-neighbors-iterator (neighbors first-atom)
            (is (integerp neighbors))
            (is (> neighbors 0))
            ;; First carbon in CCO has 1 neighbor (the other carbon)
            (let ((count 0))
              (loop while (indigo-next neighbors)
                    do (incf count))
              (is (= count 1))))
          (indigo-free first-atom))))))

(test with-components
  "Test with-components-iterator macro."
  (with-molecule (mol "CCO.CC")  ; Two components
    (with-components-iterator (components mol)
      (is (integerp components))
      (is (> components 0))
      (let ((count 0))
        (loop while (indigo-next components)
              do (incf count))
        (is (= count 2))))))

(test with-sssr
  "Test with-sssr-iterator macro."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-sssr-iterator (rings mol)
      (is (integerp rings))
      (is (> rings 0))
      (let ((count 0))
        (loop while (indigo-next rings)
              do (incf count))
        (is (= count 1))))))

(test with-stereocenters
  "Test with-stereocenters-iterator macro."
  (with-molecule (mol "C[C@H](O)CC")
    (with-stereocenters-iterator (stereos mol)
      (is (integerp stereos))
      (is (> stereos 0))
      (let ((count 0))
        (loop while (indigo-next stereos)
              do (incf count))
        (is (= count 1))))))

(test with-reactants
  "Test with-reactants-iterator macro."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (with-reactants-iterator (reactants rxn)
      (is (integerp reactants))
      (is (> reactants 0))
      (let ((count 0))
        (loop while (indigo-next reactants)
              do (incf count))
        (is (= count 2))))))

(test with-products
  "Test with-products-iterator macro."
  (with-reaction (rxn "CCO.CC>>CCOC")
    (with-products-iterator (products rxn)
      (is (integerp products))
      (is (> products 0))
      (let ((count 0))
        (loop while (indigo-next products)
              do (incf count))
        (is (= count 1))))))

;;;; =========================================================================
;;;; Nested Iterator Tests
;;;; =========================================================================

(test with-nested-iterators
  "Test nested molecule and atom iterators."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let ((symbols '())
            (atom (indigo-next atoms)))
        (loop while atom
              do (push (atom-symbol atom) symbols)
                 (indigo-free atom)
                 (setf atom (indigo-next atoms)))
        (is (equal (reverse symbols) '("C" "C" "O")))))))

;;;; =========================================================================
;;;; Stream Integration Tests
;;;; =========================================================================

(test with-stream-integration
  "Test with- macros with streams."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-atoms-iterator (atoms mol)
      (let* ((stream (indigo-stream atoms))
             (symbols '()))
        (loop while (not (stream-empty-p stream))
              do (let ((atom (stream-first stream)))
                   (push (atom-symbol atom) symbols)
                   (indigo-free atom)
                   (setf stream (stream-rest stream))))
        (is (= (length symbols) 6))
        (is (every (lambda (s) (string= s "C")) symbols))))))

;;;; =========================================================================
;;;; Advanced Iterator Tests
;;;; =========================================================================

(test subtrees-iterator
  "Test subtree iteration with size constraints."
  (with-molecule (mol "CCCC")  ; Butane
    (with-subtrees-iterator (subtrees mol 2 3)  ; 2-3 atom subtrees
      (is (integerp subtrees))
      (is (> subtrees 0))
      (let ((count 0))
        (loop for subtree = (indigo-next subtrees)
              while subtree
              do (incf count)
                 (indigo-free subtree))
        (is (> count 0))))))

(test rings-iterator
  "Test ring iteration with size constraints."
  (with-molecule (mol "c1ccc2ccccc2c1")  ; Naphthalene
    (with-rings-iterator (rings mol 5 7)  ; 5-7 atom rings
      (is (integerp rings))
      (is (> rings 0))
      (let ((count 0))
        (loop for ring = (indigo-next rings)
              while ring
              do (incf count)
                 (indigo-free ring))
        (is (= count 2))))))

(test edge-submolecules-iterator
  "Test edge submolecule iteration."
  (with-molecule (mol "CCCC")  ; Butane
    (with-edge-submolecules-iterator (submol mol 1 2)  ; 1-2 bond submolecules
      (is (integerp submol))
      (is (> submol 0))
      (let ((count 0))
        (loop for item = (indigo-next submol)
              while item
              do (incf count)
                 (indigo-free item))
        (is (> count 0))))))

(test properties-iterator
  "Test property iteration."
  (with-molecule (mol "CCO")
    (with-properties-iterator (props mol)
      (is (integerp props))
      (is (> props 0))
      (let ((count 0))
        (loop for prop = (indigo-next props)
              while prop
              do (incf count)
                 (indigo-free prop))
        (is (>= count 0))))))

(test reaction-molecules-iterator
  "Test iterating over all molecules in a reaction."
  (with-reaction (rxn "CCO>>CC")
    (with-molecules-iterator (molecules rxn)
      (is (integerp molecules))
      (is (> molecules 0))
      (let ((count 0))
        (loop for mol = (indigo-next molecules)
              while mol
              do (incf count)
                 (indigo-free mol))
        (is (= count 2))))))

(test matches-iterator
  "Test substructure match iteration."
  (with-molecule (target "c1ccc2ccccc2c1")  ; Naphthalene
    (with-query (query "c1ccccc1")  ; Benzene as query
      (with-matcher (matcher target)
        (with-matches-iterator (matches matcher query)
          (is (integerp matches))
          (is (> matches 0))
          (let ((count 0))
            (loop for match = (indigo-next matches)
                  while match
                  do (incf count)
                     (indigo-free match))
            (is (> count 0))))))))

(test tautomers-iterator
  "Test tautomer iteration."
  (with-molecule (mol "CC(=O)CC")  ; Keto form
    (with-tautomers-iterator (tautomers mol)
      (is (integerp tautomers))
      (is (> tautomers 0))
      (let ((count 0))
        (loop for tautomer = (indigo-next tautomers)
              while tautomer
              do (incf count)
                 (indigo-free tautomer))
        (is (>= count 1))))))

(test advanced-iterator-error-handling
  "Test error handling for advanced iterators."
  ;; Test with invalid molecule handle
  (signals indigo-error (iterate-subtrees -1 2 3))
  (signals indigo-error (iterate-rings -1 5 7))
  (signals indigo-error (iterate-edge-submolecules -1 1 2))
  (signals indigo-error (iterate-properties -1))

  ;; Valid range parameters should work
  (with-molecule (mol "CCO")
    (is (integerp (iterate-subtrees mol 1 1)))
    (is (integerp (iterate-rings mol 3 10)))
    (is (integerp (iterate-properties mol)))))
