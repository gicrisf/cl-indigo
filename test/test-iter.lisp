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
;;;; Iterator Cleanup Tests
;;;; =========================================================================

(test iterator-cleanup
  "Test that iterators are properly cleaned up."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        (indigo-map #'atom-symbol atoms)))))
