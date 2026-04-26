;;;; reaction.lisp - Reaction operations

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Reaction Operations
;;;; =========================================================================

;;; Note: Reaction loading is in mol/io.lisp (load-reaction-from-string, etc.)
;;; Note: Reaction iterators are in iter/iterators.lisp (iterate-reactants, etc.)
;;; Note: Reaction macros are in core/with-macros.lisp (with-reaction, etc.)

;;; Basic reaction usage:
;;;
;;; (with-reaction (rxn "CC>>C.C")
;;;   (with-reactants-iterator (reactants rxn)
;;;     (indigo-map #'canonical-smiles reactants)))
;;; => ("CC")
;;;
;;; (with-reaction (rxn "CC>>C.C")
;;;   (with-products-iterator (products rxn)
;;;     (indigo-map #'canonical-smiles products)))
;;; => ("C" "C")

;;;; =========================================================================
;;;; Atom-to-Atom Mapping (AAM) Operations
;;;; =========================================================================

(defun automap (reaction &optional (mode "discard"))
  "Automatically map reaction atoms.
MODE can be one of:
  \"discard\" - discard existing mapping (default)
  \"keep\" - keep existing mapping
  \"alter\" - alter existing mapping
  \"clear\" - clear mapping first, then map
Returns 0 on success.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (automap rxn \"discard\"))"
  (let ((result (cl-indigo.cffi::%indigo-automap reaction mode)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to automap reaction: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

(defun get-atom-mapping-number (atom)
  "Get atom mapping number for ATOM in a reaction.
Returns the mapping number as an integer, or NIL if not mapped.

Example:
  (with-reaction (rxn \"[CH3:1][CH3:2]>>[CH4:1].[CH4:2]\")
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (with-atoms-iterator (atoms mol)
          (get-atom-mapping-number (indigo-next atoms))))))"
  (cffi:with-foreign-object (number :int)
    (let ((result (cl-indigo.cffi::%indigo-get-atom-mapping-number atom number)))
      (when (< result 0)
        (error 'indigo-error
               :message (format nil "Failed to get atom mapping number: ~A"
                               (cl-indigo.cffi::%indigo-get-last-error))))
      (cffi:mem-ref number :int))))

(defun set-atom-mapping-number (atom number)
  "Set atom mapping NUMBER for ATOM in a reaction.
NUMBER should be a non-negative integer (0 means unmapped).
Returns 0 on success.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (with-atoms-iterator (atoms mol)
          (set-atom-mapping-number (indigo-next atoms) 1)))))"
  (let ((result (cl-indigo.cffi::%indigo-set-atom-mapping-number atom number)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to set atom mapping number: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

(defun clear-aam (reaction)
  "Clear all atom-to-atom mappings in REACTION.
Returns 0 on success.

Example:
  (with-reaction (rxn \"[CH3:1][CH3:2]>>[CH4:1].[CH4:2]\")
    (clear-aam rxn))"
  (let ((result (cl-indigo.cffi::%indigo-clear-aam reaction)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to clear AAM: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

(defun correct-reacting-centers (reaction)
  "Correct reacting centers in REACTION based on atom mapping.
Returns 0 on success.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (automap rxn)
    (correct-reacting-centers rxn))"
  (let ((result (cl-indigo.cffi::%indigo-correct-reacting-centers reaction)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to correct reacting centers: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

;;;; =========================================================================
;;;; Reacting Center Operations
;;;; =========================================================================

;;; Reacting center types (bit flags):
;;; 0 = RC_NOT_CENTER - not a reacting center
;;; 1 = RC_CENTER - center
;;; 2 = RC_UNCHANGED - center, bond order unchanged
;;; 4 = RC_MADE_OR_BROKEN - bond is made or broken
;;; 8 = RC_ORDER_CHANGED - bond order changed

(defun get-reacting-center (bond)
  "Get reacting center type for BOND in a reaction.
Returns an integer representing the reacting center type.
See Indigo documentation for bit flag meanings.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (automap rxn)
    (correct-reacting-centers rxn)
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (with-bonds-iterator (bonds mol)
          (get-reacting-center (indigo-next bonds))))))"
  (cffi:with-foreign-object (rc :int)
    (let ((result (cl-indigo.cffi::%indigo-get-reacting-center bond rc)))
      (when (< result 0)
        (error 'indigo-error
               :message (format nil "Failed to get reacting center: ~A"
                               (cl-indigo.cffi::%indigo-get-last-error))))
      (cffi:mem-ref rc :int))))

(defun set-reacting-center (bond rc)
  "Set reacting center type RC for BOND in a reaction.
RC should be an integer representing the reacting center type.
Returns 0 on success.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (with-reactants-iterator (reactants rxn)
      (let ((mol (indigo-next reactants)))
        (with-bonds-iterator (bonds mol)
          (set-reacting-center (indigo-next bonds) 4)))))"  ; RC_MADE_OR_BROKEN
  (let ((result (cl-indigo.cffi::%indigo-set-reacting-center bond rc)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to set reacting center: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

;;;; =========================================================================
;;;; PKA Calculations
;;;; =========================================================================

(defun build-pka-model (level threshold filename)
  "Build a pKa prediction model.
LEVEL is the model complexity level (integer).
THRESHOLD is the prediction threshold (float).
FILENAME is the path to save the model.
Returns 0 on success.

Example:
  (build-pka-model 1 0.5 \"/tmp/pka-model.dat\")"
  (let ((result (cl-indigo.cffi::%indigo-build-pka-model
                 level
                 (coerce threshold 'single-float)
                 filename)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to build pKa model: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

(defun get-acid-pka-value (atom level min-level)
  "Get acidic pKa value for ATOM.
LEVEL is the model level to use.
MIN-LEVEL is the minimum acceptable level.
Returns the pKa value as a float, or NIL if not available.

Example:
  (with-molecule (mol \"CC(=O)O\")  ; Acetic acid
    (with-atoms-iterator (atoms mol)
      (loop for atom = (indigo-next atoms)
            while atom
            when (string= (atom-symbol atom) \"O\")
            collect (get-acid-pka-value atom 1 0))))"
  (cffi:with-foreign-object (pka :float)
    (let ((result (cl-indigo.cffi::%indigo-get-acid-pka-value atom level min-level pka)))
      (if (< result 0)
          nil  ; pKa not available for this atom
          (cffi:mem-ref pka :float)))))

(defun get-basic-pka-value (atom level min-level)
  "Get basic pKa value for ATOM.
LEVEL is the model level to use.
MIN-LEVEL is the minimum acceptable level.
Returns the pKa value as a float, or NIL if not available.

Example:
  (with-molecule (mol \"CCN\")  ; Ethylamine
    (with-atoms-iterator (atoms mol)
      (loop for atom = (indigo-next atoms)
            while atom
            when (string= (atom-symbol atom) \"N\")
            collect (get-basic-pka-value atom 1 0))))"
  (cffi:with-foreign-object (pka :float)
    (let ((result (cl-indigo.cffi::%indigo-get-basic-pka-value atom level min-level pka)))
      (if (< result 0)
          nil  ; pKa not available for this atom
          (cffi:mem-ref pka :float)))))

;;;; =========================================================================
;;;; Reaction Counting Functions
;;;; =========================================================================

(defun count-reactants (reaction)
  "Get the number of reactants in REACTION.

Example:
  (with-reaction (rxn \"CCO.CC>>CCOC\")
    (count-reactants rxn))
  => 2"
  (let ((result (cl-indigo.cffi::%indigo-count-reactants reaction)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to count reactants: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))

(defun count-products (reaction)
  "Get the number of products in REACTION.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    (count-products rxn))
  => 2"
  (let ((result (cl-indigo.cffi::%indigo-count-products reaction)))
    (when (< result 0)
      (error 'indigo-error
             :message (format nil "Failed to count products: ~A"
                             (cl-indigo.cffi::%indigo-get-last-error))))
    result))
