;;;; matching.lisp - Fingerprints, similarity, and substructure matching

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Fingerprints
;;;; =========================================================================

(defun fingerprint (object type)
  "Generate fingerprint of TYPE for OBJECT.

TYPE is a string specifying the fingerprint type:
  \"sim\" - Similarity fingerprint (for Tanimoto comparison)
  \"sub\" - Substructure fingerprint (for substructure screening)
  \"full\" - Full fingerprint

Returns a fingerprint handle that must be freed.
Use WITH-FINGERPRINT for automatic cleanup.

Example:
  (with-molecule (mol \"CCO\")
    (with-fingerprint (fp mol \"sim\")
      ;; use fp for similarity calculations
      ))"
  (check-handle
   (cl-indigo.cffi::%indigo-fingerprint object type)
   "fingerprint"))

;;;; =========================================================================
;;;; Similarity
;;;; =========================================================================

(defun similarity (fp1 fp2 &optional (metric :tanimoto) &rest params)
  "Calculate similarity between fingerprints FP1 and FP2 using METRIC.

METRIC is a keyword specifying the similarity metric:
  :tanimoto (default) - Tanimoto coefficient (Jaccard index)
  :euclid-sub        - Euclidean distance for substructure fingerprints
  :tversky           - Tversky similarity (can take ALPHA BETA params)

For :tversky, optional PARAMS are ALPHA and BETA weights.

Returns a float between 0.0 and 1.0.

Examples:
  (similarity fp1 fp2)                    ; Uses :tanimoto
  (similarity fp1 fp2 :tanimoto)
  (similarity fp1 fp2 :tversky 0.7 0.3)   ; Tversky with weights"
  (let ((metric-str (concatenate 'string
                                 (string-downcase (symbol-name metric))
                                 (when params
                                   (format nil " ~{~A~^ ~}" params)))))
    (cl-indigo.cffi::%indigo-similarity fp1 fp2 metric-str)))

;;;; =========================================================================
;;;; Substructure Matching
;;;; =========================================================================

(defun substructure-matcher (target)
  "Create a substructure matcher for TARGET molecule.

Returns a matcher handle that can be used with MATCH.
The handle must be freed when done.
Use WITH-MATCHER for automatic cleanup.

Example:
  (with-molecule (mol \"c1ccccc1CCO\")
    (with-matcher (matcher mol)
      (with-query (query \"c1ccccc1\")
        (when (match matcher query)
          (format t \"Benzene ring found!~%\")))))"
  (check-handle
   (cl-indigo.cffi::%indigo-substructure-matcher target)
   "substructure-matcher"))

(defun match (matcher query)
  "Match QUERY against MATCHER.
Returns a match handle if found, NIL if no match.
The match handle contains mapping information and must be freed."
  (let ((result (cl-indigo.cffi::%indigo-match matcher query)))
    (when (cl-indigo.cffi::handle-valid-p result)
      result)))

;;;; =========================================================================
;;;; Exact Matching
;;;; =========================================================================

(defun exact-match (mol1 mol2 &optional (flags ""))
  "Check exact match between MOL1 and MOL2.

FLAGS is an optional string specifying match options:
  \"\"     - Default matching
  \"TAU\" - Tautomer matching
  \"STE\" - Stereo matching

Flags can be combined: \"TAU STE\"

Returns T if molecules match exactly, NIL otherwise.

Example:
  (with-molecule* ((m1 \"CCO\")
                   (m2 \"OCC\"))
    (exact-match m1 m2))
  => T"
  (let ((result (cl-indigo.cffi::%indigo-exact-match mol1 mol2 flags)))
    (cl-indigo.cffi::handle-valid-p result)))
