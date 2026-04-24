;;;; test-bonds.lisp - Bond property tests

(in-package #:cl-indigo-tests)

(def-suite bond-tests
  :description "Tests for bond properties"
  :in :cl-indigo-tests)

(in-suite bond-tests)

;;;; =========================================================================
;;;; Basic Bond Property Tests
;;;; =========================================================================

(test bond-source
  "Test bond-source returns atom handle."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (source-atom (bond-source bond)))
        (is (integerp source-atom))
        (is (> source-atom 0))
        (let ((idx (atom-index source-atom)))
          (is (integerp idx))
          (is (= idx 0)))))))

(test bond-destination
  "Test bond-destination returns atom handle."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (dest-atom (bond-destination bond)))
        (is (integerp dest-atom))
        (is (> dest-atom 0))
        (let ((idx (atom-index dest-atom)))
          (is (integerp idx))
          (is (= idx 1)))))))

(test bond-order-single
  "Test single bonds."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (order (bond-order bond)))
        (is (keywordp order))
        (is (eq order :single))))))

(test bond-order-double
  "Test double bonds."
  (with-molecule (mol "C=C")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (order (bond-order bond)))
        (is (keywordp order))
        (is (eq order :double))))))

(test bond-order-triple
  "Test triple bonds."
  (with-molecule (mol "C#C")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (order (bond-order bond)))
        (is (keywordp order))
        (is (eq order :triple))))))

(test bond-order-aromatic
  "Test aromatic bonds."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (order (bond-order bond)))
        (is (keywordp order))
        (is (eq order :aromatic))))))

(test bond-stereo
  "Test bond-stereo returns keyword value."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let* ((bond (indigo-next bonds-iter))
             (stereo (bond-stereo bond)))
        (is (keywordp stereo))
        (is (eq stereo :none))))))

;;;; =========================================================================
;;;; Complete Bond Data Collection Tests
;;;; =========================================================================

(test collect-all-bonds
  "Test collecting all bond properties from ethanol."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond-data '())
            (bond (indigo-next bonds-iter)))
        (loop while bond
              do (let* ((source-atom (bond-source bond))
                        (dest-atom (bond-destination bond))
                        (source-idx (atom-index source-atom))
                        (dest-idx (atom-index dest-atom))
                        (order (bond-order bond))
                        (stereo (bond-stereo bond)))
                   (push (list source-idx dest-idx order stereo) bond-data))
                 (setf bond (indigo-next bonds-iter)))
        (setf bond-data (nreverse bond-data))

        ;; Should have 2 bonds (C-C and C-O)
        (is (= (length bond-data) 2))

        ;; Verify first bond (C-C)
        (let ((bond1 (nth 0 bond-data)))
          (is (= (nth 0 bond1) 0))   ; source index
          (is (= (nth 1 bond1) 1))   ; destination index
          (is (eq (nth 2 bond1) :single))   ; order (single)
          (is (eq (nth 3 bond1) :none)))    ; stereo (none)

        ;; Verify second bond (C-O)
        (let ((bond2 (nth 1 bond-data)))
          (is (= (nth 0 bond2) 1))   ; source index
          (is (= (nth 1 bond2) 2))   ; destination index
          (is (eq (nth 2 bond2) :single))   ; order (single)
          (is (eq (nth 3 bond2) :none)))))))

(test benzene-bonds
  "Test all bonds in benzene are aromatic."
  (with-molecule (mol "c1ccccc1")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond-orders '())
            (bond (indigo-next bonds-iter)))
        (loop while bond
              do (push (bond-order bond) bond-orders)
                 (setf bond (indigo-next bonds-iter)))

        ;; Should have 6 bonds
        (is (= (length bond-orders) 6))

        ;; All should be aromatic keywords
        (is (every (lambda (o) (eq o :aromatic)) bond-orders))))))

(test bond-connectivity
  "Test that bonds connect valid atom indices."
  (with-molecule (mol "CCCO")
    ;; First count atoms
    (let ((atom-count 0))
      (with-atoms-iterator (atoms-iter mol)
        (let ((atom (indigo-next atoms-iter)))
          (loop while atom
                do (incf atom-count)
                   (setf atom (indigo-next atoms-iter)))))

      ;; Now check bonds
      (with-bonds-iterator (bonds-iter mol)
        (let ((bond (indigo-next bonds-iter)))
          (loop while bond
                do (let* ((src-atom (bond-source bond))
                          (dst-atom (bond-destination bond))
                          (src-idx (atom-index src-atom))
                          (dst-idx (atom-index dst-atom)))
                     ;; All indices should be within valid range
                     (is (>= src-idx 0))
                     (is (< src-idx atom-count))
                     (is (>= dst-idx 0))
                     (is (< dst-idx atom-count))
                     ;; Source and destination should be different
                     (is (not (= src-idx dst-idx))))
                   (setf bond (indigo-next bonds-iter))))))))

;;;; =========================================================================
;;;; Multiple Bond Types Test
;;;; =========================================================================

(test bond-mixed-orders
  "Test molecule with different bond orders."
  (with-molecule (mol "C=CC#N")  ; ethylene + nitrile
    (with-bonds-iterator (bonds-iter mol)
      (let ((orders '())
            (bond (indigo-next bonds-iter)))
        (loop while bond
              do (push (bond-order bond) orders)
                 (setf bond (indigo-next bonds-iter)))
        (setf orders (nreverse orders))

        ;; Should have 3 bonds
        (is (= (length orders) 3))
        ;; Should contain: single, double, triple keywords
        (is (member :single orders))
        (is (member :double orders))
        (is (member :triple orders))))))

;;;; =========================================================================
;;;; Bond Count Tests
;;;; =========================================================================

(test bond-count-simple
  "Test bond count for simple molecules."
  (with-molecule (mol "CCO")
    (with-bonds-iterator (bonds-iter mol)
      (let ((count 0)
            (bond (indigo-next bonds-iter)))
        (loop while bond
              do (incf count)
                 (setf bond (indigo-next bonds-iter)))
        (is (= count 2))))))

(test bond-count-cyclic
  "Test bond count for cyclic molecule."
  (with-molecule (mol "C1CCC1")  ; Cyclobutane
    (with-bonds-iterator (bonds-iter mol)
      (let ((count 0)
            (bond (indigo-next bonds-iter)))
        (loop while bond
              do (incf count)
                 (setf bond (indigo-next bonds-iter)))
        (is (= count 4))))))

;;;; =========================================================================
;;;; Error Handling Tests
;;;; =========================================================================

(test bond-properties-all-valid
  "Test that all bond property functions return valid values."
  (with-molecule (mol "c1ccccc1")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        (loop while bond
              do (let ((src-atom (bond-source bond))
                       (dst-atom (bond-destination bond))
                       (order (bond-order bond))
                       (stereo (bond-stereo bond)))
                   ;; Atom handles should return integers
                   (is (integerp src-atom))
                   (is (integerp dst-atom))
                   ;; Order and stereo should return keywords
                   (is (keywordp order))
                   (is (keywordp stereo))
                   ;; Atom handles should be positive
                   (is (> src-atom 0))
                   (is (> dst-atom 0))
                   ;; Order should be valid keyword
                   (is (member order '(:query :single :double :triple :aromatic)))
                   ;; Stereo should be valid keyword
                   (is (member stereo '(:none :either :up :down :cis :trans))))
                 (setf bond (indigo-next bonds-iter)))))))

;;;; =========================================================================
;;;; Enum Mapping Tests
;;;; =========================================================================

(test bond-order-raw-functions
  "Test that raw integer functions still work."
  (with-molecule (mol "C=C")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        ;; Raw function should return integer
        (is (integerp (bond-order-code (bond-order bond))))
        (is (= (bond-order-code :double) 2))
        ;; Wrapper should return keyword
        (is (eq (bond-order bond) :double))))))

(test bond-stereo-raw-functions
  "Test that raw stereo integer functions still work."
  (with-molecule (mol "CC")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        ;; Raw function should return integer
        (is (integerp (bond-stereo-code (bond-stereo bond))))
        (is (= (bond-stereo-code :none) 0))
        ;; Wrapper should return keyword
        (is (eq (bond-stereo bond) :none))))))

(test bond-order-reverse-mapping
  "Test converting keywords back to codes."
  (is (= (bond-order-code :single) 1))
  (is (= (bond-order-code :double) 2))
  (is (= (bond-order-code :triple) 3))
  (is (= (bond-order-code :aromatic) 4))
  (is (= (bond-order-code :query) 0)))

(test bond-stereo-reverse-mapping
  "Test converting stereo keywords back to codes."
  (is (= (bond-stereo-code :none) 0))
  (is (= (bond-stereo-code :up) 5))
  (is (= (bond-stereo-code :down) 6))
  (is (= (bond-stereo-code :either) 4))
  (is (= (bond-stereo-code :cis) 7))
  (is (= (bond-stereo-code :trans) 8)))

(test bond-predicates
  "Test convenience predicate functions."
  ;; Single bond
  (with-molecule (mol "CC")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        (is (bond-single-p bond))
        (is-false (bond-double-p bond))
        (is-false (bond-triple-p bond))
        (is-false (bond-aromatic-p bond)))))

  ;; Double bond
  (with-molecule (mol "C=C")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        (is (bond-double-p bond))
        (is-false (bond-single-p bond)))))

  ;; Triple bond
  (with-molecule (mol "C#C")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        (is (bond-triple-p bond))
        (is-false (bond-single-p bond)))))

  ;; Aromatic bond
  (with-molecule (mol "c1ccccc1")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        (is (bond-aromatic-p bond))
        (is-false (bond-single-p bond))))))

(test bond-has-stereo-predicate
  "Test stereochemistry predicate."
  (with-molecule (mol "CC")
    (with-bonds-iterator (bonds-iter mol)
      (let ((bond (indigo-next bonds-iter)))
        ;; Simple molecules typically have no stereochemistry
        (is-false (bond-has-stereo-p bond))))))
