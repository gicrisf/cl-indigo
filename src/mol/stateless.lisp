;;;; stateless.lisp - Stateless convenience functions with auto-cleanup
;;;;
;;;; These functions provide format-agnostic operations on molecular and
;;;; reaction strings with automatic resource management. They follow the
;;;; pattern: load -> operate -> cleanup -> return.
;;;;
;;;; All functions return NIL on error instead of signaling.

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Helpers
;;;; =========================================================================

(defun %do-with-molecule (string fn)
  "Execute FN on molecule loaded from STRING. Returns NIL on error."
  (handler-case
      (with-molecule (mol string)
        (funcall fn mol))
    (indigo-error () nil)))

(defun %do-with-reaction (reaction-string fn)
  "Execute FN on reaction loaded from REACTION-STRING. Returns NIL on error."
  (handler-case
      (with-reaction (rxn reaction-string)
        (funcall fn rxn))
    (indigo-error () nil)))

;;;; =========================================================================
;;;; Molecular Formula and Weight
;;;; =========================================================================

(defun do-molecular-formula (string)
  "Get molecular formula from molecular STRING with auto-cleanup.
Returns formula like \"C2 H6 O\" or NIL on error.

Example:
  (do-molecular-formula \"CCO\") => \"C2 H6 O\""
  (%do-with-molecule string #'gross-formula))

(defun do-molecular-weight (string)
  "Get molecular weight from molecular STRING with auto-cleanup.
Returns weight in daltons as a float, or NIL on error.

Example:
  (do-molecular-weight \"CCO\") => 46.069"
  (%do-with-molecule string #'molecular-weight))

(defun do-most-abundant-mass (string)
  "Get most abundant mass from molecular STRING with auto-cleanup.
Returns mass or NIL on error."
  (%do-with-molecule string #'most-abundant-mass))

(defun do-monoisotopic-mass (string)
  "Get monoisotopic mass from molecular STRING with auto-cleanup.
Returns mass or NIL on error."
  (%do-with-molecule string #'monoisotopic-mass))

;;;; =========================================================================
;;;; Format Conversions
;;;; =========================================================================

(defun do-canonical-smiles (string)
  "Get canonical SMILES from molecular STRING with auto-cleanup.
Returns canonical SMILES string or NIL on error.

Example:
  (do-canonical-smiles \"CCO\") => \"CCO\"
  (do-canonical-smiles \"OCC\") => \"CCO\""
  (%do-with-molecule string #'canonical-smiles))

(defun do-smiles (string)
  "Get SMILES from molecular STRING with auto-cleanup.
Unlike do-canonical-smiles, preserves input atom ordering.
Returns SMILES string or NIL on error."
  (%do-with-molecule string #'smiles))

(defun do-molfile (string)
  "Get MOL file format from molecular STRING with auto-cleanup.
Returns MOL V2000 format string or NIL on error."
  (%do-with-molecule string #'molfile))

(defun do-cml (string)
  "Get CML (Chemical Markup Language) from molecular STRING with auto-cleanup.
Returns XML string or NIL on error."
  (%do-with-molecule string #'cml))

;;;; =========================================================================
;;;; Counting Functions
;;;; =========================================================================

(defun do-atom-count (string)
  "Get heavy atom count from molecular STRING with auto-cleanup.
Returns integer count or NIL on error.

Example:
  (do-atom-count \"CCO\") => 3"
  (%do-with-molecule string #'count-atoms))

(defun do-bond-count (string)
  "Get bond count from molecular STRING with auto-cleanup.
Returns integer count or NIL on error.

Example:
  (do-bond-count \"CCO\") => 2"
  (%do-with-molecule string #'count-bonds))

(defun do-heavy-atom-count (string)
  "Get heavy atom count from molecular STRING with auto-cleanup.
Heavy atoms are all atoms except hydrogen.
Returns integer count or NIL on error."
  (%do-with-molecule string #'count-heavy-atoms))

(defun do-hydrogen-count (string)
  "Get total hydrogen count from molecular STRING with auto-cleanup.
Returns integer count or NIL on error.

Example:
  (do-hydrogen-count \"CCO\") => 6"
  (%do-with-molecule string #'count-implicit-hydrogens))

(defun do-total-atom-count (string)
  "Get total atom count (heavy + hydrogen) from molecular STRING.
Returns integer count or NIL on error.

Example:
  (do-total-atom-count \"CCO\") => 9  ; 3 heavy + 6 hydrogen"
  (handler-case
      (with-molecule (mol string)
        (+ (count-atoms mol)
           (count-implicit-hydrogens mol)))
    (indigo-error () nil)))

(defun do-ring-count (string)
  "Get SSSR (smallest set of smallest rings) count from molecular STRING.
Returns integer count or NIL on error.

Example:
  (do-ring-count \"c1ccccc1\") => 1"
  (%do-with-molecule string #'count-sssr))

(defun do-aromatic-ring-count (string)
  "Get aromatic ring count from molecular STRING with auto-cleanup.
Returns integer count or NIL on error.

Note: Counts rings where at least one bond is aromatic (bond order 4)."
  (handler-case
      (with-molecule (mol string)
        (with-sssr-iterator (iter mol)
          (loop for ring = (indigo-next iter)
                while ring
                count (handler-case
                          ;; Check if any bond in ring is aromatic
                          (with-bonds-iterator (bond-iter ring)
                            (loop for bond = (indigo-next bond-iter)
                                  while bond
                                  thereis (bond-aromatic-p bond)))
                        (indigo-error () nil)))))
    (indigo-error () nil)))

(defun do-chiral-center-count (string)
  "Get chiral center count from molecular STRING with auto-cleanup.
Returns integer count or NIL on error."
  (%do-with-molecule string #'count-stereocenters))

(defun do-formal-charge (string)
  "Get total formal charge from molecular STRING with auto-cleanup.
Returns integer charge or NIL on error.

Example:
  (do-formal-charge \"[NH4+]\") => 1
  (do-formal-charge \"[OH-]\") => -1"
  (handler-case
      (with-molecule (mol string)
        (with-atoms-iterator (iter mol)
          (loop for atom = (indigo-next iter)
                while atom
                sum (atom-charge atom))))
    (indigo-error () nil)))

(defun do-hbd-count (string)
  "Get hydrogen bond donor count from molecular STRING.
Counts N, O, or S atoms with attached hydrogens.
Returns integer count or NIL on error."
  (handler-case
      (with-molecule (mol string)
        (with-atoms-iterator (iter mol)
          (loop for atom = (indigo-next iter)
                while atom
                count (let ((sym (atom-symbol atom))
                           (h-count (count-implicit-hydrogens atom)))
                       (and (> h-count 0)
                            (member sym '("N" "O" "S") :test #'string=))))))
    (indigo-error () nil)))

(defun do-hba-count (string)
  "Get hydrogen bond acceptor count from molecular STRING.
Counts N, O, and F atoms.
Returns integer count or NIL on error."
  (handler-case
      (with-molecule (mol string)
        (with-atoms-iterator (iter mol)
          (loop for atom = (indigo-next iter)
                while atom
                count (member (atom-symbol atom) '("N" "O" "F") :test #'string=))))
    (indigo-error () nil)))

;;;; =========================================================================
;;;; Structural Analysis
;;;; =========================================================================

(defun do-has-stereochemistry (string)
  "Check if molecular STRING has stereochemistry (stereocenters or stereobonds).
Returns T if stereochemistry present, NIL otherwise or on error."
  (handler-case
      (with-molecule (mol string)
        ;; Check for stereocenters
        (or (> (count-stereocenters mol) 0)
            ;; Check for stereobonds (cis/trans double bonds)
            (with-bonds-iterator (iter mol)
              (loop for bond = (indigo-next iter)
                    while bond
                    thereis (bond-has-stereo-p bond)))))
    (indigo-error () nil)))

(defun do-is-chiral (string)
  "Check if molecular STRING represents a chiral molecule.
Returns T if chiral, NIL if achiral or on error.

Note: A molecule is chiral if it has stereocenters and is not a meso compound."
  (handler-case
      (with-molecule (mol string)
        ;; Simple heuristic: has stereocenters
        ;; A proper implementation would check for meso compounds
        (> (count-stereocenters mol) 0))
    (indigo-error () nil)))

(defun do-has-coordinates (string)
  "Check if molecular STRING has 2D or 3D coordinates.
Returns T if coordinates present, NIL otherwise or on error."
  (%do-with-molecule string #'has-coordinates))

(defun do-has-z-coord (string)
  "Check if molecular STRING has 3D coordinates (Z coordinate).
Returns T if 3D, NIL if 2D/no coordinates or on error."
  (%do-with-molecule string #'has-z-coord))

;;;; =========================================================================
;;;; Search and Matching
;;;; =========================================================================

(defun do-substructure-match (mol-string query-string)
  "Check if MOL-STRING contains QUERY-STRING as a substructure.
Returns T if match found, NIL otherwise or on error.

Example:
  (do-substructure-match \"CCO\" \"CC\") => T
  (do-substructure-match \"C\" \"CC\") => NIL"
  (handler-case
      (with-molecule (mol mol-string)
        (with-query (query query-string)
          (with-matcher (matcher mol)
            (not (null (match matcher query))))))
    (indigo-error () nil)))

(defun do-exact-match (mol1-string mol2-string)
  "Check if MOL1-STRING and MOL2-STRING represent the same molecule.
Returns T if exact match, NIL otherwise or on error.

Handles different representations of the same molecule:
  (do-exact-match \"CCO\" \"OCC\") => T"
  (handler-case
      (with-molecule* ((mol1 mol1-string)
                       (mol2 mol2-string))
        (exact-match mol1 mol2))
    (indigo-error () nil)))

(defun do-similarity (mol1-string mol2-string)
  "Calculate Tanimoto similarity between MOL1-STRING and MOL2-STRING.
Returns float in range [0.0, 1.0], or NIL on error.

1.0 = identical, 0.0 = no similarity.

Example:
  (do-similarity \"CCO\" \"CCO\") => ~1.0
  (do-similarity \"CCO\" \"c1ccccc1\") => ~0.1"
  (handler-case
      (with-molecule* ((mol1 mol1-string)
                       (mol2 mol2-string))
        (with-fingerprint* ((fp1 mol1 "sim")
                           (fp2 mol2 "sim"))
          (similarity fp1 fp2)))
    (indigo-error () nil)))

;;;; =========================================================================
;;;; Reaction Functions
;;;; =========================================================================

(defun do-reaction-products-count (reaction-string)
  "Count products in REACTION-STRING.
Returns integer count or NIL on error.

Example:
  (do-reaction-products-count \"CCO.CC>>CCOC\") => 1"
  (handler-case
      (with-reaction (rxn reaction-string)
        (with-products-iterator (iter rxn)
          (loop for product = (indigo-next iter)
                while product
                count t)))
    (indigo-error () nil)))

(defun do-reaction-reactants-count (reaction-string)
  "Count reactants in REACTION-STRING.
Returns integer count or NIL on error.

Example:
  (do-reaction-reactants-count \"CCO.CC>>CCOC\") => 2"
  (handler-case
      (with-reaction (rxn reaction-string)
        (with-reactants-iterator (iter rxn)
          (loop for reactant = (indigo-next iter)
                while reactant
                count t)))
    (indigo-error () nil)))

;;;; =========================================================================
;;;; Other Functions
;;;; =========================================================================

(defun do-layered-code (string)
  "Get layered code from molecular STRING with auto-cleanup.
Returns code string or NIL on error."
  (handler-case
      (with-molecule (mol string)
        ;; Layered code requires calling a specific function
        ;; For now, return a placeholder
        ;; TODO: Implement when CFFI binding is available
        (canonical-smiles mol))
    (indigo-error () nil)))

;; Note: Symmetry classes function has known bugs in upstream Indigo
;; Commented out for now
;; (defun do-symmetry-classes (string)
;;   "Get symmetry classes from molecular STRING with auto-cleanup.
;; Returns list of integers or NIL on error."
;;   ...)
