;;;; test-atoms.lisp - Atom property tests

(in-package #:cl-indigo-tests)

(def-suite atom-tests
  :description "Tests for atom properties"
  :in :cl-indigo-tests)

(in-suite atom-tests)

;;;; =========================================================================
;;;; Basic Atom Property Tests
;;;; =========================================================================

(test atom-symbol
  "Test atom symbol extraction."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((symbols (stream-collect (stream-map #'atom-symbol stream))))
        (is (equal '("C" "C" "O") symbols))))))

(test atom-index
  "Test atom index."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((indices (stream-collect (stream-map #'atom-index stream))))
        (is (equal '(0 1 2) indices))))))

;;;; =========================================================================
;;;; Charge Tests
;;;; =========================================================================

(test atom-charge-neutral
  "Test charge of neutral atoms."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((charges (stream-collect (stream-map #'atom-charge stream))))
        (is (every #'zerop charges))))))

(test atom-charge-negative
  "Test negative charge."
  (with-molecule (mol "[O-]CCO")  ; Ethoxide
    (with-atoms-stream (stream mol)
      (let ((first-charge (atom-charge (stream-first stream))))
        (is (= -1 first-charge))))))

(test atom-charge-positive
  "Test positive charge."
  (with-molecule (mol "[NH4+]")  ; Ammonium
    (with-atoms-stream (stream mol)
      (let ((charge (atom-charge (stream-first stream))))
        (is (= 1 charge))))))

;;;; =========================================================================
;;;; Coordinate Tests
;;;; =========================================================================

(test atom-xyz-no-coords
  "Test atom-xyz when no coordinates."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      ;; Without layout, coordinates may be nil or all zeros
      (let ((coords (atom-xyz (stream-first stream))))
        (is (or (null coords)
                (and (listp coords) (= 3 (length coords)))))))))

(test atom-xyz-with-layout
  "Test atom-xyz after layout."
  (with-molecule (mol "CCO")
    (layout mol)
    (with-atoms-stream (stream mol)
      (let ((coords (atom-xyz (stream-first stream))))
        (is (listp coords))
        (is (= 3 (length coords)))
        (is (every #'floatp coords))))))

;;;; =========================================================================
;;;; Radical Tests
;;;; =========================================================================

(test atom-radical-none
  "Test non-radical atom."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (is (eq :none (atom-radical (stream-first stream))))
      (is (not (atom-radical-p (stream-first stream)))))))

;; Note: Testing actual radicals requires specific radical SMILES notation
;; which may vary by Indigo version
