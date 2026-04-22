;;;; test-bonds.lisp - Bond property tests

(in-package #:cl-indigo-tests)

(def-suite bond-tests
  :description "Tests for bond properties"
  :in :cl-indigo-tests)

(in-suite bond-tests)

;;;; =========================================================================
;;;; Bond Order Tests
;;;; =========================================================================

(test bond-order-single
  "Test single bonds."
  (with-molecule (mol "CCO")
    (with-bonds-stream (stream mol)
      (let ((orders (stream-collect (stream-map #'bond-order stream))))
        (is (every (lambda (o) (eq o :single)) orders))))))

(test bond-order-double
  "Test double bonds."
  (with-molecule (mol "C=C")  ; Ethene
    (with-bonds-stream (stream mol)
      (is (eq :double (bond-order (stream-first stream)))))))

(test bond-order-triple
  "Test triple bonds."
  (with-molecule (mol "C#C")  ; Ethyne
    (with-bonds-stream (stream mol)
      (is (eq :triple (bond-order (stream-first stream)))))))

(test bond-order-aromatic
  "Test aromatic bonds."
  (with-molecule (mol "c1ccccc1")  ; Benzene (aromatic)
    (with-bonds-stream (stream mol)
      (let ((orders (stream-collect (stream-map #'bond-order stream))))
        (is (every (lambda (o) (eq o :aromatic)) orders))))))

;;;; =========================================================================
;;;; Bond Order Predicate Tests
;;;; =========================================================================

(test bond-single-p
  "Test bond-single-p predicate."
  (with-molecule (mol "CCO")
    (with-bonds-stream (stream mol)
      (is (bond-single-p (stream-first stream))))))

(test bond-double-p
  "Test bond-double-p predicate."
  (with-molecule (mol "C=C")
    (with-bonds-stream (stream mol)
      (is (bond-double-p (stream-first stream))))))

(test bond-aromatic-p
  "Test bond-aromatic-p predicate."
  (with-molecule (mol "c1ccccc1")
    (with-bonds-stream (stream mol)
      (is (bond-aromatic-p (stream-first stream))))))

;;;; =========================================================================
;;;; Bond Atom Tests
;;;; =========================================================================

(test bond-source-destination
  "Test bond-source and bond-destination."
  (with-molecule (mol "CCO")
    (with-bonds-stream (stream mol)
      (let ((bond (stream-first stream)))
        (let ((src (bond-source bond))
              (dst (bond-destination bond)))
          (is (integerp src))
          (is (integerp dst))
          (is (not (= src dst))))))))

;;;; =========================================================================
;;;; Bond Stereo Tests
;;;; =========================================================================

(test bond-stereo-none
  "Test bonds without stereochemistry."
  (with-molecule (mol "CCO")
    (with-bonds-stream (stream mol)
      (let ((stereos (stream-collect (stream-map #'bond-stereo stream))))
        (is (every (lambda (s) (eq s :none)) stereos))))))

;; Note: Testing specific stereo (up/down/cis/trans) requires molecules
;; with defined stereochemistry which can be complex to set up
