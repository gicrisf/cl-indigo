;;;; test-streams.lisp - Lazy stream tests

(in-package #:cl-indigo-tests)

(def-suite stream-tests
  :description "Tests for lazy stream operations"
  :in :cl-indigo-tests)

(in-suite stream-tests)

;;;; =========================================================================
;;;; Basic Stream Tests
;;;; =========================================================================

(test stream-creation
  "Test basic stream creation from iterator."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let ((stream (indigo-stream atoms)))
        ;; Stream should be a lazy-stream struct
        (is (lazy-stream-p stream))
        ;; Forcing should give us a cons cell
        (let ((forced (stream-force stream)))
          (is-true forced)
          ;; First element should be an integer handle
          (is (integerp (car forced)))
          ;; Rest should be a lazy-stream
          (is (lazy-stream-p (cdr forced))))))))

(test stream-first
  "Test stream-first."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (is (string= "C" (atom-symbol (stream-first stream)))))))

(test stream-rest
  "Test stream-rest."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((rest (stream-rest stream))
             (second (stream-first rest)))
        (is (string= "C" (atom-symbol second)))))))

(test stream-rest-advancing
  "Test advancing through a stream."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (let* ((stream (indigo-stream atoms))
             (first-val (stream-first stream))
             (stream2 (stream-rest stream))
             (second-val (stream-first stream2)))
        ;; First and second values should be different
        (is (not (= first-val second-val)))
        ;; Both should be valid handles
        (is (integerp first-val))
        (is (integerp second-val))
        (cl-indigo.cffi::%indigo-free first-val)
        (cl-indigo.cffi::%indigo-free second-val)))))

(test stream-empty-p
  "Test stream-empty-p."
  (with-molecule (mol "C")  ; Single carbon
    (with-atoms-stream (stream mol)
      (is (not (stream-empty-p stream)))
      (let ((rest (stream-rest stream)))
        (is (stream-empty-p rest))))))

(test stream-empty-p-with-cleanup
  "Test checking if stream is empty with proper cleanup."
  (with-molecule (mol "C")
    (with-atoms-iterator (atoms mol)
      (let ((stream (indigo-stream atoms)))
        ;; Single carbon - stream should not be empty
        (is (not (stream-empty-p stream)))
        ;; Get and free the handle
        (let ((atom (stream-first stream)))
          (is (integerp atom))
          (cl-indigo.cffi::%indigo-free atom))
        ;; Advance to next (which should be empty)
        (setf stream (stream-rest stream))
        ;; Now, stream should be empty
        (is (stream-empty-p stream))))))

;;;; =========================================================================
;;;; Stream Map Tests
;;;; =========================================================================

(test stream-basic-iteration
  "Test basic stream iteration without map."
  (with-molecule (mol "CCO")  ; Ethanol
    (with-atoms-iterator (atoms mol)
      (let ((stream (indigo-stream atoms)))
        ;; Get first atom
        (let* ((first-handle (stream-first stream))
               (first-sym (atom-symbol first-handle)))
          (is (string= "C" first-sym))
          (cl-indigo.cffi::%indigo-free first-handle))
        ;; Advance and get second
        (setf stream (stream-rest stream))
        (let* ((second-handle (stream-first stream))
               (second-sym (atom-symbol second-handle)))
          (is (string= "C" second-sym))
          (cl-indigo.cffi::%indigo-free second-handle))
        ;; Advance and get third
        (setf stream (stream-rest stream))
        (let* ((third-handle (stream-first stream))
               (third-sym (atom-symbol third-handle)))
          (is (string= "O" third-sym))
          (cl-indigo.cffi::%indigo-free third-handle))))))

(test stream-map
  "Test stream-map."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (collected (stream-collect symbols)))
        (is (equal '("C" "C" "O") collected))))))

(test stream-map-symbols
  "Test mapping symbol extraction over stream."
  (with-molecule (mol "CCO")  ; Ethanol
    (with-atoms-stream (stream mol)
      (let ((symbols (stream-map #'atom-symbol stream)))
        ;; First symbol should be "C"
        (is (string= "C" (stream-first symbols)))
        ;; Advance to second
        (setf symbols (stream-rest symbols))
        (is (string= "C" (stream-first symbols)))
        ;; Advance to third
        (setf symbols (stream-rest symbols))
        (is (string= "O" (stream-first symbols)))
        ;; Advance past end
        (setf symbols (stream-rest symbols))
        (is (stream-empty-p symbols))))))

(test stream-map-charges
  "Test mapping charge extraction over stream."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-atoms-stream (stream mol)
      (let ((charges (stream-map #'atom-charge stream)))
        ;; All carbons in benzene should have charge 0
        (is (= 0 (stream-first charges)))
        (setf charges (stream-rest charges))
        (is (= 0 (stream-first charges)))
        (setf charges (stream-rest charges))
        (is (= 0 (stream-first charges)))))))

(test stream-map-empty
  "Test mapping over empty stream."
  (with-molecule (mol "C")
    (with-atoms-stream (stream mol)
      ;; Advance to empty stream (past the single carbon)
      (setf stream (stream-rest stream))
      ;; Map over empty stream should return empty stream
      (let ((mapped (stream-map #'atom-symbol stream)))
        (is (stream-empty-p mapped))))))

(test stream-map-laziness
  "Test that map is truly lazy - doesn't force entire stream."
  (let ((call-count 0))
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (let ((mapped (stream-map
                       (lambda (atom)
                         (incf call-count)
                         (atom-symbol atom))
                       stream)))
          ;; Creating the mapped stream should not call the function
          (is (= 0 call-count))
          ;; Accessing first element should call once
          (let ((first-val (stream-first mapped)))
            (is (= 1 call-count))
            (is (string= "C" first-val)))
          ;; Advancing to second element (without accessing)
          (setf mapped (stream-rest mapped))
          (is (= 1 call-count))  ; Still 1 because we haven't accessed car yet
          ;; Access second element
          (let ((second-val (stream-first mapped)))
            (is (= 2 call-count))
            (is (string= "C" second-val))))))))

(test stream-map-chaining
  "Test chaining multiple map operations."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* (;; First map: extract symbols
             (symbols (stream-map #'atom-symbol stream))
             ;; Second map: convert to lowercase
             (lower (stream-map #'string-downcase symbols))
             ;; Third map: add prefix
             (prefixed (stream-map
                        (lambda (s) (concatenate 'string "atom-" s))
                        lower)))
        ;; Check first element through all transformations
        (is (string= "atom-c" (stream-first prefixed)))
        ;; Check second element
        (setf prefixed (stream-rest prefixed))
        (is (string= "atom-c" (stream-first prefixed)))
        ;; Check third element
        (setf prefixed (stream-rest prefixed))
        (is (string= "atom-o" (stream-first prefixed)))))))

(test stream-map-complex-molecule
  "Test mapping over a more complex molecule."
  (with-molecule (mol "CC(C)C(=O)O")  ; Isobutyric acid
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (collected nil))
        ;; Collect all symbols
        (loop while (not (stream-empty-p symbols))
              do (push (stream-first symbols) collected)
                 (setf symbols (stream-rest symbols)))
        ;; Should have 6 heavy atoms: C-C-C-C-O-O
        (is (= 6 (length collected)))
        (is (equal '("O" "O" "C" "C" "C" "C") collected))))))

;;;; =========================================================================
;;;; Stream Collect Tests
;;;; =========================================================================

(test stream-collect
  "Test stream-collect."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((atoms (stream-collect stream)))
        (is (= 3 (length atoms)))))))

(test stream-collect-basic
  "Test basic stream collection."
  (with-molecule (mol "CCO")  ; Ethanol
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (collected (stream-collect symbols)))
        ;; Should collect all 3 symbols in order
        (is (equal '("C" "C" "O") collected))))))

(test stream-collect-empty
  "Test collecting from an empty stream."
  (with-molecule (mol "C")
    (with-atoms-stream (stream mol)
      ;; Advance to empty stream
      (setf stream (stream-rest stream))
      ;; Collect from empty stream should return empty list
      (let ((collected (stream-collect stream)))
        (is (equal '() collected))))))

(test stream-collect-charges
  "Test collecting charges from a molecule."
  (with-molecule (mol "c1ccccc1")  ; Benzene
    (with-atoms-stream (stream mol)
      (let* ((charges (stream-map #'atom-charge stream))
             (collected (stream-collect charges)))
        ;; All 6 carbons in benzene should have charge 0
        (is (equal '(0 0 0 0 0 0) collected))))))

(test stream-collect-with-chaining
  "Test collecting from chained map operations."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* (;; First map: extract symbols
             (symbols (stream-map #'atom-symbol stream))
             ;; Second map: convert to lowercase
             (lower (stream-map #'string-downcase symbols))
             ;; Third map: add prefix
             (prefixed (stream-map
                        (lambda (s) (concatenate 'string "atom-" s))
                        lower))
             ;; Collect final result
             (collected (stream-collect prefixed)))
        ;; Should have all transformations applied
        (is (equal '("atom-c" "atom-c" "atom-o") collected))))))

(test stream-collect-complex-molecule
  "Test collecting from a complex molecule."
  (with-molecule (mol "CC(C)C(=O)O")  ; Isobutyric acid
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (collected (stream-collect symbols)))
        ;; Should have 6 heavy atoms: C-C-C-C-O-O
        (is (= 6 (length collected)))
        (is (equal '("C" "C" "C" "C" "O" "O") collected))))))

(test stream-collect-preserves-order
  "Test that collect preserves stream order."
  (with-molecule (mol "CCCCC")  ; Pentane
    (with-atoms-stream (stream mol)
      (let* ((indices (stream-map #'atom-index stream))
             (collected (stream-collect indices)))
        ;; Indices should be in order: 0, 1, 2, 3, 4
        (is (equal '(0 1 2 3 4) collected))))))

(test stream-collect-bonds
  "Test collecting bond information from a molecule."
  (with-molecule (mol "CCO")
    (with-bonds-stream (stream mol)
      (let* ((bond-orders (stream-map #'bond-order stream))
             (collected (stream-collect bond-orders)))
        ;; CCO has 2 single bonds
        (is (equal '(:single :single) collected))))))

(test stream-collect-partial-consumption
  "Test that collect works after partial stream consumption."
  (with-molecule (mol "CCCCCC")  ; Hexane (6 carbons)
    (with-atoms-stream (stream mol)
      (let ((symbols (stream-map #'atom-symbol stream)))
        ;; Consume first 2 elements
        (is (string= "C" (stream-first symbols)))
        (setf symbols (stream-rest symbols))
        (is (string= "C" (stream-first symbols)))
        (setf symbols (stream-rest symbols))
        ;; Collect remaining elements
        (let ((collected (stream-collect symbols)))
          ;; Should have remaining 4 carbons
          (is (equal '("C" "C" "C" "C") collected)))))))

;;;; =========================================================================
;;;; Stream Take Tests
;;;; =========================================================================

(test stream-take
  "Test stream-take."
  (with-molecule (mol "CCCCCC")  ; Hexane (6 carbons)
    (with-atoms-stream (stream mol)
      (let* ((first-three (stream-take 3 stream))
             (symbols (stream-map #'atom-symbol first-three))
             (collected (stream-collect symbols)))
        (is (= 3 (length collected)))
        (is (every (lambda (s) (string= s "C")) collected))))))

(test stream-take-basic
  "Test basic stream take operation."
  (with-molecule (mol "CCCCCC")  ; Hexane (6 carbons)
    (with-atoms-stream (stream mol)
      (let* ((first-three (stream-take 3 stream))
             (symbols (stream-map #'atom-symbol first-three))
             (collected (stream-collect symbols)))
        ;; Should have exactly 3 carbons
        (is (equal '("C" "C" "C") collected))))))

(test stream-take-zero
  "Test that taking 0 elements returns empty stream."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((taken (stream-take 0 stream)))
        ;; Should be empty stream
        (is (stream-empty-p taken))))))

(test stream-take-more-than-available
  "Test taking more elements than available."
  (with-molecule (mol "CCO")  ; 3 atoms
    (with-atoms-stream (stream mol)
      (let* ((taken (stream-take 10 stream))
             (symbols (stream-map #'atom-symbol taken))
             (collected (stream-collect symbols)))
        ;; Should only have 3 atoms (all available)
        (is (equal '("C" "C" "O") collected))))))

(test stream-take-one
  "Test taking exactly one element."
  (with-molecule (mol "CCCCC")
    (with-atoms-stream (stream mol)
      (let ((first-one (stream-take 1 stream)))
        ;; Should have first carbon
        (is (string= "C" (atom-symbol (stream-first first-one))))
        ;; Rest should be empty
        (is (stream-empty-p (stream-rest first-one)))))))

(test stream-take-laziness
  "Test that take is lazy - doesn't force unnecessary elements."
  (with-molecule (mol "CCCCCC")  ; Hexane (6 carbons)
    (with-atoms-stream (stream mol)
      (let* ((count 0)
             ;; Map with side-effect counter
             (counted (stream-map
                       (lambda (atom)
                         (incf count)
                         (atom-symbol atom))
                       stream))
             ;; Take only 3 elements
             (taken (stream-take 3 counted)))
        ;; Counter should still be 0 (nothing forced yet)
        (is (= 0 count))
        ;; Force first element
        (stream-first taken)
        (is (= 1 count))
        ;; Collect all - should only force 3 total
        (stream-collect taken)
        (is (= 3 count))))))

(test stream-take-composition
  "Test composing take with multiple maps."
  (with-molecule (mol "CCCCCC")
    (with-atoms-stream (stream mol)
      (let* ((first-four (stream-take 4 stream))
             (symbols (stream-map #'atom-symbol first-four))
             (lower (stream-map #'string-downcase symbols))
             (prefixed (stream-map
                        (lambda (s) (concatenate 'string "atom-" s))
                        lower))
             (collected (stream-collect prefixed)))
        ;; Should have exactly 4 transformed elements
        (is (equal '("atom-c" "atom-c" "atom-c" "atom-c") collected))))))

(test stream-take-after-consumption
  "Test taking from a partially consumed stream."
  (with-molecule (mol "CCCCCC")  ; Hexane
    (with-atoms-stream (stream mol)
      (let ((symbols (stream-map #'atom-symbol stream)))
        ;; Consume first 2 elements
        (stream-first symbols)
        (setf symbols (stream-rest symbols))
        (stream-first symbols)
        (setf symbols (stream-rest symbols))
        ;; Take next 2 from remaining 4
        (let* ((next-two (stream-take 2 symbols))
               (collected (stream-collect next-two)))
          ;; Should have 2 carbons
          (is (equal '("C" "C") collected)))))))

(test stream-take-empty-stream
  "Test taking from an empty stream."
  (with-molecule (mol "C")
    (with-atoms-stream (stream mol)
      ;; Advance to empty
      (setf stream (stream-rest stream))
      (let ((taken (stream-take 5 stream)))
        ;; Should be empty
        (is (stream-empty-p taken))))))

(test stream-take-bonds
  "Test taking bond elements."
  (with-molecule (mol "CCCCCC")  ; Hexane has 5 bonds
    (with-bonds-stream (stream mol)
      (let* ((first-three (stream-take 3 stream))
             (orders (stream-map #'bond-order first-three))
             (collected (stream-collect orders)))
        ;; Should have exactly 3 single bonds
        (is (equal '(:single :single :single) collected))))))

(test stream-take-preserves-memoization
  "Test that take preserves stream memoization."
  (with-molecule (mol "CCCC")
    (with-atoms-stream (stream mol)
      (let* ((count 0)
             ;; Map with side-effect counter
             (counted (stream-map
                       (lambda (atom)
                         (incf count)
                         (atom-symbol atom))
                       stream))
             (taken (stream-take 2 counted)))
        ;; Access first element twice
        (stream-first taken)
        (stream-first taken)
        ;; Should only increment count once (memoized)
        (is (= 1 count))))))

;;;; =========================================================================
;;;; Stream Filter Tests
;;;; =========================================================================

(test stream-filter
  "Test stream-filter."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             (symbols (stream-map #'atom-symbol carbons))
             (collected (stream-collect symbols)))
        (is (equal '("C" "C") collected))))))

(test stream-filter-basic
  "Test basic stream filter operation."
  (with-molecule (mol "CCO")  ; Ethanol
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             (symbols (stream-map #'atom-symbol carbons))
             (collected (stream-collect symbols)))
        ;; Should have exactly 2 carbons
        (is (equal '("C" "C") collected))))))

(test stream-filter-all-match
  "Test filtering when all elements match."
  (with-molecule (mol "CCCCCC")  ; Hexane - all carbons
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             (collected (stream-collect carbons)))
        ;; Should have all 6 atoms
        (is (= 6 (length collected)))))))

(test stream-filter-none-match
  "Test filtering when no elements match."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((nitrogens (stream-filter
                         (lambda (atom)
                           (string= (atom-symbol atom) "N"))
                         stream))
             (collected (stream-collect nitrogens)))
        ;; Should be empty
        (is (equal '() collected))))))

(test stream-filter-charged-atoms
  "Test filtering for charged atoms."
  (with-molecule (mol "[O-]CCO")  ; Ethoxide ion
    (with-atoms-stream (stream mol)
      (let* ((charged (stream-filter
                       (lambda (atom)
                         (not (= 0 (atom-charge atom))))
                       stream))
             (charges (stream-map #'atom-charge charged))
             (collected (stream-collect charges)))
        ;; Should have one charged atom with charge -1
        (is (equal '(-1) collected))))))

(test stream-filter-laziness
  "Test that filter is lazy - doesn't force unnecessary elements."
  (with-molecule (mol "CCCCCO")  ; Pentanol
    (with-atoms-stream (stream mol)
      (let* ((count 0)
             ;; Map with side-effect counter
             (counted (stream-map
                       (lambda (atom)
                         (incf count)
                         atom)
                       stream))
             ;; Filter for carbons only
             (carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       counted)))
        ;; Counter should still be 0 (nothing forced yet)
        (is (= 0 count))
        ;; Force first element - should only check elements until first carbon
        (stream-first carbons)
        (is (= 1 count))))))

(test stream-filter-composition
  "Test composing filter with map and take."
  (with-molecule (mol "CCCCCCCO")  ; Heptanol
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             (first-three (stream-take 3 carbons))
             (indices (stream-map #'atom-index first-three))
             (collected (stream-collect indices)))
        ;; Should have indices of first 3 carbons
        (is (equal '(0 1 2) collected))))))

(test stream-filter-multiple-filters
  "Test chaining multiple filters."
  (with-molecule (mol "c1ccccc1")  ; Benzene (aromatic carbons)
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             ;; Filter for even indices
             (even-indices (stream-filter
                            (lambda (atom)
                              (= 0 (mod (atom-index atom) 2)))
                            carbons))
             (indices (stream-map #'atom-index even-indices))
             (collected (stream-collect indices)))
        ;; Should have indices 0, 2, 4
        (is (equal '(0 2 4) collected))))))

(test stream-filter-after-map
  "Test filtering after mapping."
  (with-molecule (mol "CCCCO")
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             ;; Filter for carbons by symbol string
             (carbons (stream-filter
                       (lambda (sym) (string= sym "C"))
                       symbols))
             (collected (stream-collect carbons)))
        ;; Should have 4 "C" symbols
        (is (equal '("C" "C" "C" "C") collected))))))

(test stream-filter-empty-stream
  "Test filtering an empty stream."
  (with-molecule (mol "C")
    (with-atoms-stream (stream mol)
      ;; Advance to empty
      (setf stream (stream-rest stream))
      (let* ((filtered (stream-filter
                        (lambda (atom) t)
                        stream))
             (collected (stream-collect filtered)))
        ;; Should be empty
        (is (equal '() collected))))))

(test stream-filter-preserves-memoization
  "Test that filter preserves stream memoization."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((count 0)
             ;; Map with side-effect counter
             (counted (stream-map
                       (lambda (atom)
                         (incf count)
                         atom)
                       stream))
             (carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       counted)))
        ;; Access first element twice
        (stream-first carbons)
        (stream-first carbons)
        ;; Should only increment count once (memoized)
        (is (= 1 count))))))

(test stream-filter-bonds
  "Test filtering bond elements."
  (with-molecule (mol "C=CC")  ; Propene (double and single bonds)
    (with-bonds-stream (stream mol)
      (let* ((double-bonds (stream-filter
                            (lambda (bond)
                              (eq (bond-order bond) :double))
                            stream))
             (collected (stream-collect double-bonds)))
        ;; Should have exactly 1 double bond
        (is (= 1 (length collected)))))))

;;;; =========================================================================
;;;; Stream Fold Tests
;;;; =========================================================================

(test stream-fold
  "Test stream-fold."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((sum (stream-fold
                  (lambda (acc atom)
                    (+ acc (atom-index atom)))
                  0
                  stream)))
        (is (= 3 sum))))))  ; 0 + 1 + 2

(test stream-fold-sum
  "Test folding to sum atom indices."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((sum (stream-fold
                  (lambda (acc atom)
                    (+ acc (atom-index atom)))
                  0
                  stream)))
        ;; Should sum indices: 0 + 1 + 2 = 3
        (is (= 3 sum))))))

(test stream-fold-count
  "Test folding to count specific atoms."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((carbon-count (stream-fold
                           (lambda (acc atom)
                             (if (string= (atom-symbol atom) "C")
                                 (1+ acc)
                                 acc))
                           0
                           stream)))
        ;; Should count 2 carbons
        (is (= 2 carbon-count))))))

(test stream-fold-concat
  "Test folding to build a string."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((formula (stream-fold
                      (lambda (acc atom)
                        (concatenate 'string acc (atom-symbol atom)))
                      ""
                      stream)))
        ;; Should build "CCO"
        (is (string= "CCO" formula))))))

(test stream-fold-max
  "Test folding to find maximum value."
  (with-molecule (mol "[O-]C[NH3+]")
    (with-atoms-stream (stream mol)
      (let ((max-charge (stream-fold
                         (lambda (acc atom)
                           (max acc (atom-charge atom)))
                         most-negative-fixnum
                         stream)))
        ;; Should find max charge of +1
        (is (= 1 max-charge))))))

(test stream-fold-min
  "Test folding to find minimum value."
  (with-molecule (mol "[O-]C[NH3+]")
    (with-atoms-stream (stream mol)
      (let ((min-charge (stream-fold
                         (lambda (acc atom)
                           (min acc (atom-charge atom)))
                         most-positive-fixnum
                         stream)))
        ;; Should find min charge of -1
        (is (= -1 min-charge))))))

(test stream-fold-empty
  "Test folding an empty stream."
  (with-molecule (mol "C")
    (with-atoms-stream (stream mol)
      ;; Advance to empty
      (setf stream (stream-rest stream))
      (let ((result (stream-fold
                     (lambda (acc atom) (1+ acc))
                     0
                     stream)))
        ;; Should return initial value unchanged
        (is (= 0 result))))))

(test stream-fold-build-list
  "Test folding to build a list (like collect)."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((symbols-stream (stream-map #'atom-symbol stream))
             (result (stream-fold
                      (lambda (acc sym) (cons sym acc))
                      nil
                      symbols-stream)))
        ;; Should build reversed list
        (is (equal '("O" "C" "C") result))
        ;; Nreverse to get same order as collect
        (is (equal '("C" "C" "O") (nreverse result)))))))

(test stream-fold-with-filter
  "Test folding after filtering."
  (with-molecule (mol "CCCCCO")
    (with-atoms-stream (stream mol)
      (let* ((carbons (stream-filter
                       (lambda (atom)
                         (string= (atom-symbol atom) "C"))
                       stream))
             (indices (stream-map #'atom-index carbons))
             (sum (stream-fold #'+ 0 indices)))
        ;; Should sum indices of 5 carbons: 0+1+2+3+4 = 10
        (is (= 10 sum))))))

(test stream-fold-with-take
  "Test folding after taking elements."
  (with-molecule (mol "CCCCCC")
    (with-atoms-stream (stream mol)
      (let* ((first-three (stream-take 3 stream))
             (indices (stream-map #'atom-index first-three))
             (sum (stream-fold #'+ 0 indices)))
        ;; Should sum first 3 indices: 0+1+2 = 3
        (is (= 3 sum))))))

(test stream-fold-product
  "Test folding to compute product."
  (with-molecule (mol "CCCC")
    (with-atoms-stream (stream mol)
      (let* ((indices (stream-map
                       (lambda (atom) (1+ (atom-index atom)))
                       stream))
             (product (stream-fold #'* 1 indices)))
        ;; Should compute 1 * 2 * 3 * 4 = 24
        (is (= 24 product))))))

(test stream-fold-complex-accumulator
  "Test folding with complex accumulator (alist)."
  (with-molecule (mol "CCCOO")
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (counts (stream-fold
                      (lambda (acc sym)
                        (let ((entry (assoc sym acc :test #'string=)))
                          (if entry
                              (progn
                                (setf (cdr entry) (1+ (cdr entry)))
                                acc)
                              (cons (cons sym 1) acc))))
                      nil
                      symbols)))
        ;; Should count: C=3, O=2
        (is (= 3 (cdr (assoc "C" counts :test #'string=))))
        (is (= 2 (cdr (assoc "O" counts :test #'string=))))))))

(test stream-fold-all-match
  "Test folding to check if all elements match predicate."
  (with-molecule (mol "CCCCCC")
    (with-atoms-stream (stream mol)
      (let ((all-carbons (stream-fold
                          (lambda (acc atom)
                            (and acc (string= (atom-symbol atom) "C")))
                          t
                          stream)))
        ;; Should be true - all are carbons
        (is (eq t all-carbons))))))

(test stream-fold-any-match
  "Test folding to check if any element matches predicate."
  (with-molecule (mol "CCCO")
    (with-atoms-stream (stream mol)
      (let ((has-oxygen (stream-fold
                         (lambda (acc atom)
                           (or acc (string= (atom-symbol atom) "O")))
                         nil
                         stream)))
        ;; Should be true - has oxygen
        (is-true has-oxygen)))))

(test stream-fold-bonds
  "Test folding over bonds."
  (with-molecule (mol "C=CC")  ; Propene
    (with-bonds-stream (stream mol)
      (let ((bond-count (stream-fold
                         (lambda (acc bond)
                           (declare (ignore bond))
                           (1+ acc))
                         0
                         stream)))
        ;; Should have 2 bonds
        (is (= 2 bond-count))))))

(test stream-fold-left-associative
  "Test that fold is left-associative."
  (with-molecule (mol "CCC")
    (with-atoms-stream (stream mol)
      (let* ((indices (stream-map #'atom-index stream))
             (result (stream-fold
                      (lambda (acc idx)
                        (format nil "(~A-~D)" acc idx))
                      "X"
                      indices)))
        ;; Should build left-to-right: (((X-0)-1)-2)
        (is (string= "(((X-0)-1)-2)" result))))))

;;;; =========================================================================
;;;; With-style Macro Tests
;;;; =========================================================================

(test with-stream-from-iterator-basic
  "Test basic usage of with-stream-from-iterator macro."
  (with-molecule (mol "CCO")
    (with-atoms-iterator (atoms mol)
      (with-stream-from-iterator (stream atoms)
        ;; Stream should be a lazy-stream
        (is (lazy-stream-p stream))
        ;; Force and check first element
        (let ((forced (stream-force stream)))
          (is-true forced)
          (is (integerp (car forced))))))))

(test with-stream-from-iterator-iteration
  "Test iterating through stream with automatic cleanup."
  (let ((symbols nil))
    (with-molecule (mol "CCO")
      (with-atoms-iterator (atoms mol)
        (with-stream-from-iterator (stream atoms)
          ;; Collect all symbols (elements are still tracked for cleanup)
          (loop while (not (stream-empty-p stream))
                do (let ((atom (stream-first stream)))
                     (push (atom-symbol atom) symbols)
                     (setf stream (stream-rest stream)))))))
    ;; All elements should have been freed automatically
    (is (equal '("O" "C" "C") symbols))))

(test with-stream-from-iterator-bonds
  "Test with-stream-from-iterator with bonds iterator."
  (let ((bond-count 0))
    (with-molecule (mol "CCO")
      (with-bonds-iterator (bonds mol)
        (with-stream-from-iterator (stream bonds)
          ;; Count bonds
          (loop while (not (stream-empty-p stream))
                do (incf bond-count)
                   (setf stream (stream-rest stream))))))
    ;; CCO has 2 bonds
    (is (= 2 bond-count))))

(test with-stream-from-iterator-with-map
  "Test combining with-stream-from-iterator with stream-map."
  (let ((symbols nil))
    (with-molecule (mol "c1ccccc1")  ; Benzene
      (with-atoms-iterator (atoms mol)
        (with-stream-from-iterator (stream atoms)
          ;; Map to extract symbols (note: original handles are tracked and freed)
          (let ((symbol-stream (stream-map #'atom-symbol stream)))
            ;; Collect first 3 symbols
            (dotimes (_ 3)
              (push (stream-first symbol-stream) symbols)
              (setf symbol-stream (stream-rest symbol-stream)))))))
    ;; Should have 3 carbon symbols
    (is (= 3 (length symbols)))
    (is (equal '("C" "C" "C") symbols))))

(test with-stream-from-iterator-partial-consumption
  "Test that only forced elements are tracked and freed."
  (let ((first-symbol nil))
    (with-molecule (mol "CCCCCCCCCC")  ; 10 carbons
      (with-atoms-iterator (atoms mol)
        (with-stream-from-iterator (stream atoms)
          ;; Only force first element
          (let ((atom (stream-first stream)))
            (setf first-symbol (atom-symbol atom))))))
    ;; Should have successfully gotten first symbol
    (is (string= "C" first-symbol))))

(test with-stream-from-iterator-error-handling
  "Test that elements are freed even when an error occurs."
  (let ((symbols nil)
        (error-caught nil))
    (handler-case
        (with-molecule (mol "CCO")
          (with-atoms-iterator (atoms mol)
            (with-stream-from-iterator (stream atoms)
              ;; Force first two elements
              (push (atom-symbol (stream-first stream)) symbols)
              (setf stream (stream-rest stream))
              (push (atom-symbol (stream-first stream)) symbols)
              ;; Trigger an error
              (error "Test error"))))
      (error () (setf error-caught t)))
    ;; Error should have been caught
    (is-true error-caught)
    ;; But we should have collected 2 symbols before the error
    (is (= 2 (length symbols)))
    (is (equal '("C" "C") symbols))))

(test with-stream-from-iterator-empty-iterator
  "Test with-stream-from-iterator with an empty iterator (no rings in acyclic molecule)."
  (with-molecule (mol "CCC")  ; Propane (no rings)
    (with-sssr-iterator (rings mol)
      (with-stream-from-iterator (stream rings)
        ;; Stream should be empty
        (is (stream-empty-p stream))))))

(test with-stream-from-iterator-rings
  "Test with-stream-from-iterator with SSSR rings iterator."
  (let ((ring-count 0))
    (with-molecule (mol "c1ccc2ccccc2c1")  ; Naphthalene (2 rings)
      (with-sssr-iterator (rings mol)
        (with-stream-from-iterator (stream rings)
          ;; Count rings
          (loop while (not (stream-empty-p stream))
                do (incf ring-count)
                   (setf stream (stream-rest stream))))))
    ;; Naphthalene has 2 SSSR rings
    (is (= 2 ring-count))))

(test with-stream-from-iterator-nested
  "Test nesting multiple with-stream-from-iterator macros."
  (let ((total-neighbors 0))
    (with-molecule (mol "CCC")  ; Propane
      (with-atoms-iterator (atoms mol)
        (with-stream-from-iterator (atom-stream atoms)
          ;; For each atom
          (loop while (not (stream-empty-p atom-stream))
                do (let ((atom (stream-first atom-stream)))
                     ;; Count its neighbors using a nested stream
                     (with-neighbors-iterator (neighbors atom)
                       (with-stream-from-iterator (neighbor-stream neighbors)
                         (loop while (not (stream-empty-p neighbor-stream))
                               do (incf total-neighbors)
                                  (setf neighbor-stream (stream-rest neighbor-stream))))))
                   (setf atom-stream (stream-rest atom-stream))))))
    ;; Propane: C-C-C
    ;; First C has 1 neighbor, middle C has 2 neighbors, last C has 1 neighbor
    ;; Total: 1 + 2 + 1 = 4
    (is (= 4 total-neighbors))))

;;;; =========================================================================
;;;; Stream Cleanup Tests
;;;; =========================================================================

(test stream-cleanup
  "Test that streams properly clean up elements."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (stream-collect (stream-map #'atom-symbol stream))))))

(test stream-cleanup-with-map
  "Test cleanup after map operations."
  (with-reference-check
    (with-molecule (mol "c1ccccc1")  ; Benzene
      (with-atoms-stream (stream mol)
        (let* ((symbols (stream-map #'atom-symbol stream))
               (lower (stream-map #'string-downcase symbols)))
          (stream-collect lower))))))

(test stream-cleanup-with-filter
  "Test cleanup after filter operations."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (let* ((carbons (stream-filter
                         (lambda (atom) (string= (atom-symbol atom) "C"))
                         stream)))
          (stream-collect (stream-map #'atom-symbol carbons)))))))

(test stream-cleanup-with-take
  "Test cleanup after take operations."
  (with-reference-check
    (with-molecule (mol "CCCCCC")
      (with-atoms-stream (stream mol)
        (let ((first-three (stream-take 3 stream)))
          (stream-collect (stream-map #'atom-symbol first-three)))))))

(test stream-cleanup-with-fold
  "Test cleanup after fold operations."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (stream-fold
         (lambda (acc atom)
           (+ acc (atom-index atom)))
         0
         stream)))))

(test stream-cleanup-partial-consumption
  "Test cleanup after partial stream consumption."
  (with-reference-check
    (with-molecule (mol "CCCCCC")
      (with-atoms-stream (stream mol)
        (let ((symbols (stream-map #'atom-symbol stream)))
          ;; Only consume first 2
          (stream-first symbols)
          (stream-first (stream-rest symbols)))))))

;;;; =========================================================================
;;;; Stream-Iterator Bridge Macro Tests
;;;; =========================================================================

(test with-components-stream-bridge
  "Test components stream macro."
  (with-molecule (mol "C.C.C")  ; Three separate components
    (with-components-stream (stream mol)
      (is (lazy-stream-p stream))
      (let ((count 0))
        (while (not (stream-empty-p stream))
          (is (integerp (stream-first stream)))
          (setf stream (stream-rest stream))
          (incf count))
        (is (= count 3))))))

(test with-sssr-stream-bridge
  "Test SSSR rings stream macro."
  (with-molecule (mol "c1ccc2ccccc2c1")  ; Naphthalene (2 rings)
    (with-sssr-stream (stream mol)
      (is (lazy-stream-p stream))
      (let ((count 0))
        (while (not (stream-empty-p stream))
          (is (integerp (stream-first stream)))
          (setf stream (stream-rest stream))
          (incf count))
        (is (= count 2))))))

(test with-sssr-stream-empty
  "Test SSSR rings stream with acyclic molecule."
  (with-molecule (mol "CCC")  ; Propane (no rings)
    (with-sssr-stream (stream mol)
      (is (lazy-stream-p stream))
      (is (stream-empty-p stream)))))

(test with-rings-stream-bridge
  "Test rings stream macro with size range."
  (with-molecule (mol "c1ccccc1")  ; Benzene (one 6-membered ring)
    (with-rings-stream (stream mol 3 7)
      (is (lazy-stream-p stream))
      (is-not (stream-empty-p stream))
      (let ((first (stream-first stream)))
        (is (integerp first))))))

(test with-subtrees-stream-bridge
  "Test subtrees stream macro with size range."
  (with-molecule (mol "CCO")
    (with-subtrees-stream (stream mol 1 3)
      (is (lazy-stream-p stream))
      (is-not (stream-empty-p stream))
      (let ((first (stream-first stream)))
        (is (integerp first))))))

(test with-stereocenters-stream-bridge
  "Test stereocenters stream macro."
  (with-molecule (mol "C[C@H](O)N")  ; Molecule with stereocenter
    (with-stereocenters-stream (stream mol)
      (is (lazy-stream-p stream))
      (let ((count 0))
        (while (not (stream-empty-p stream))
          (is (integerp (stream-first stream)))
          (setf stream (stream-rest stream))
          (incf count))
        (is (= count 1))))))

(test with-stereocenters-stream-empty
  "Test stereocenters stream with molecule without stereocenters."
  (with-molecule (mol "CCO")  ; Ethanol (no stereocenters)
    (with-stereocenters-stream (stream mol)
      (is (lazy-stream-p stream))
      (is (stream-empty-p stream)))))

(test with-neighbors-stream-bridge
  "Test neighbors stream macro."
  (with-molecule (mol "CCC")  ; Propane
    (with-atoms-iterator (atoms mol)
      (indigo-next atoms)  ; Skip first
      (let ((middle-carbon (indigo-next atoms)))  ; Get middle carbon
        (with-neighbors-stream (stream middle-carbon)
          (is (lazy-stream-p stream))
          (let ((count 0))
            (while (not (stream-empty-p stream))
              (is (integerp (stream-first stream)))
              (setf stream (stream-rest stream))
              (incf count))
            (is (= count 2))))
        (indigo-free middle-carbon)))))

(test with-reactants-stream-bridge
  "Test reactants stream macro."
  (with-reaction (rxn "CCO.CC>>CCOCC")
    (with-reactants-stream (stream rxn)
      (is (lazy-stream-p stream))
      (let ((count 0))
        (while (not (stream-empty-p stream))
          (is (integerp (stream-first stream)))
          (setf stream (stream-rest stream))
          (incf count))
        (is (= count 2))))))

(test with-products-stream-bridge
  "Test products stream macro."
  (with-reaction (rxn "CCO.CC>>CCOCC")
    (with-products-stream (stream rxn)
      (is (lazy-stream-p stream))
      (let ((count 0))
        (while (not (stream-empty-p stream))
          (is (integerp (stream-first stream)))
          (setf stream (stream-rest stream))
          (incf count))
        (is (= count 1))))))
