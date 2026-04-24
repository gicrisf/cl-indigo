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

;;;; =========================================================================
;;;; Radical Predicate Tests
;;;; =========================================================================

(test radical-predicates
  "Test convenience predicate functions."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        ;; Normal atoms should not be radicals
        (is-false (atom-radical-p atom))
        (is-false (atom-singlet-p atom))
        (is-false (atom-doublet-p atom))
        (is-false (atom-triplet-p atom))))))

(test radical-predicates-with-radicals
  "Test predicates with actual radical molecules."
  ;; Test singlet carbene
  (with-molecule (mol "[CH2]")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        (is-true (atom-radical-p atom))
        (is-true (atom-singlet-p atom))
        (is-false (atom-doublet-p atom))
        (is-false (atom-triplet-p atom)))))

  ;; Test doublet methyl radical
  (with-molecule (mol "[CH3]")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        (is-true (atom-radical-p atom))
        (is-true (atom-doublet-p atom))
        (is-false (atom-singlet-p atom))
        (is-false (atom-triplet-p atom))))))

;;;; =========================================================================
;;;; Radical Type Tests
;;;; =========================================================================

(test radical-oxygen-singlet
  "Test oxygen radical [O] - Indigo treats it as singlet."
  (with-molecule (mol "[O]")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        (when atom
          (let ((keyword (atom-radical atom)))
            (is (eq keyword :singlet))))))))

(test radical-methyl-doublet
  "Test methyl radical [CH3] - should be doublet."
  (with-molecule (mol "[CH3]")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        (when atom
          (let ((keyword (atom-radical atom)))
            (is (eq keyword :doublet))))))))

(test radical-carbene-singlet
  "Test carbene [CH2] - Indigo treats it as singlet."
  (with-molecule (mol "[CH2]")
    (with-atoms-iterator (atoms-iter mol)
      (let ((atom (indigo-next atoms-iter)))
        (when atom
          (let ((keyword (atom-radical atom)))
            (is (eq keyword :singlet))))))))

(test radical-molecular-oxygen
  "Test molecular oxygen O=O - normal molecule, no radical."
  (with-molecule (mol "O=O")  ; Molecular oxygen
    (with-atoms-iterator (atoms-iter mol)
      (let* ((atom (indigo-next atoms-iter))
             (keyword (atom-radical atom)))
        (is (eq keyword :none))))))

;;;; =========================================================================
;;;; Integration Tests
;;;; =========================================================================

(test all-atoms-return-radical-keywords
  "Test that all atoms return valid radical keywords."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-atoms-iterator (atoms-iter mol)
      (let ((radicals '())
            (atom (indigo-next atoms-iter)))
        (loop while (and atom (> atom 0))
              do (push (atom-radical atom) radicals)
                 (setf atom (indigo-next atoms-iter)))

        ;; All values should be keyword symbols
        (is (every #'keywordp radicals))
        ;; For normal molecules, all should be :none
        (is (every (lambda (r) (eq r :none)) radicals))))))
