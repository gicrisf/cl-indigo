;;;; test-streams.lisp - Lazy stream tests

(in-package #:cl-indigo-tests)

(def-suite stream-tests
  :description "Tests for lazy stream operations"
  :in :cl-indigo-tests)

(in-suite stream-tests)

;;;; =========================================================================
;;;; Basic Stream Tests
;;;; =========================================================================

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

(test stream-empty-p
  "Test stream-empty-p."
  (with-molecule (mol "C")  ; Single carbon
    (with-atoms-stream (stream mol)
      (is (not (stream-empty-p stream)))
      (let ((rest (stream-rest stream)))
        (is (stream-empty-p rest))))))

;;;; =========================================================================
;;;; Stream Combinator Tests
;;;; =========================================================================

(test stream-map
  "Test stream-map."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let* ((symbols (stream-map #'atom-symbol stream))
             (collected (stream-collect symbols)))
        (is (equal '("C" "C" "O") collected))))))

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

(test stream-take
  "Test stream-take."
  (with-molecule (mol "CCCCCC")  ; Hexane (6 carbons)
    (with-atoms-stream (stream mol)
      (let* ((first-three (stream-take 3 stream))
             (symbols (stream-map #'atom-symbol first-three))
             (collected (stream-collect symbols)))
        (is (= 3 (length collected)))
        (is (every (lambda (s) (string= s "C")) collected))))))

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

(test stream-collect
  "Test stream-collect."
  (with-molecule (mol "CCO")
    (with-atoms-stream (stream mol)
      (let ((atoms (stream-collect stream)))
        (is (= 3 (length atoms)))))))

;;;; =========================================================================
;;;; Stream Cleanup Tests
;;;; =========================================================================

(test stream-cleanup
  "Test that streams properly clean up elements."
  (with-reference-check
    (with-molecule (mol "CCO")
      (with-atoms-stream (stream mol)
        (stream-collect (stream-map #'atom-symbol stream))))))
