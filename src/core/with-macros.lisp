;;;; with-macros.lisp - Resource management macros

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Molecule Resource Macros
;;;; =========================================================================

(defmacro with-molecule ((var smiles-string) &body body)
  "Load molecule from SMILES-STRING with automatic cleanup.
VAR is bound to the molecule handle within BODY.
The molecule is automatically freed when BODY exits (normally or via error).

Example:
  (with-molecule (mol \"CCO\")
    (molecular-weight mol))
  => 46.069"
  (with-gensyms (handle)
    `(let ((,handle (load-molecule-from-string ,smiles-string)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-mol-file ((var filename) &body body)
  "Load molecule from FILENAME with automatic cleanup.
VAR is bound to the molecule handle within BODY.

Example:
  (with-mol-file (mol \"molecule.mol\")
    (canonical-smiles mol))"
  (with-gensyms (handle)
    `(let ((,handle (load-molecule-from-file ,filename)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-query ((var query-string) &body body)
  "Load query molecule from QUERY-STRING with automatic cleanup.
VAR is bound to the query handle within BODY.

Example:
  (with-query (query \"C=O\")
    (smiles query))"
  (with-gensyms (handle)
    `(let ((,handle (load-query-molecule-from-string ,query-string)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-smarts ((var smarts-string) &body body)
  "Load SMARTS pattern from SMARTS-STRING with automatic cleanup.
VAR is bound to the pattern handle within BODY.

Example:
  (with-smarts (pattern \"[#6]=[#8]\")
    (smiles pattern))"
  (with-gensyms (handle)
    `(let ((,handle (load-smarts-from-string ,smarts-string)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-fingerprint ((var obj type) &body body)
  "Generate fingerprint of TYPE for OBJ with automatic cleanup.
TYPE can be \"sim\" (similarity) or \"sub\" (substructure).
VAR is bound to the fingerprint handle within BODY.

Example:
  (with-molecule (mol \"CCO\")
    (with-fingerprint (fp mol \"sim\")
      ;; use fp for similarity calculations
      ))"
  (with-gensyms (handle)
    `(let ((,handle (fingerprint ,obj ,type)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-matcher ((var target) &body body)
  "Create substructure matcher for TARGET with automatic cleanup.
VAR is bound to the matcher handle within BODY.

Example:
  (with-molecule (mol \"c1ccccc1CCO\")
    (with-matcher (matcher mol)
      (with-query (query \"c1ccccc1\")
        (match matcher query))))"
  (with-gensyms (handle)
    `(let ((,handle (substructure-matcher ,target)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-reaction ((var rxn-string) &body body)
  "Load reaction from RXN-STRING with automatic cleanup.
VAR is bound to the reaction handle within BODY.

Example:
  (with-reaction (rxn \"CC>>C.C\")
    ;; iterate reactants/products
    )"
  (with-gensyms (handle)
    `(let ((,handle (load-reaction-from-string ,rxn-string)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

;;;; =========================================================================
;;;; Iterator Resource Macros
;;;; =========================================================================

(defmacro with-atoms-iterator ((var molecule) &body body)
  "Create atoms iterator for MOLECULE with automatic cleanup.
VAR is bound to the iterator handle within BODY.

Example:
  (with-molecule (mol \"CCO\")
    (with-atoms-iterator (atoms mol)
      (loop for atom = (indigo-next atoms)
            while atom
            collect (atom-symbol atom))))"
  (with-gensyms (handle)
    `(let ((,handle (iterate-atoms ,molecule)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-bonds-iterator ((var molecule) &body body)
  "Create bonds iterator for MOLECULE with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-bonds ,molecule)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-neighbors-iterator ((var atom) &body body)
  "Create neighbors iterator for ATOM with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-neighbors ,atom)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-components-iterator ((var molecule) &body body)
  "Create components iterator for MOLECULE with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-components ,molecule)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-sssr-iterator ((var molecule) &body body)
  "Create SSSR (smallest set of smallest rings) iterator with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-sssr ,molecule)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-stereocenters-iterator ((var molecule) &body body)
  "Create stereocenters iterator for MOLECULE with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-stereocenters ,molecule)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-reactants-iterator ((var reaction) &body body)
  "Create reactants iterator for REACTION with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-reactants ,reaction)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-products-iterator ((var reaction) &body body)
  "Create products iterator for REACTION with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-products ,reaction)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-subtrees-iterator ((var molecule min-atoms max-atoms) &body body)
  "Create subtrees iterator for MOLECULE with size range and automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-subtrees ,molecule ,min-atoms ,max-atoms)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-rings-iterator ((var molecule min-atoms max-atoms) &body body)
  "Create rings iterator for MOLECULE with size range and automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-rings ,molecule ,min-atoms ,max-atoms)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-edge-submolecules-iterator ((var molecule min-bonds max-bonds) &body body)
  "Create edge submolecules iterator with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-edge-submolecules ,molecule ,min-bonds ,max-bonds)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-properties-iterator ((var handle) &body body)
  "Create properties iterator for HANDLE with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle-iter)
    `(let ((,handle-iter (iterate-properties ,handle)))
       (unwind-protect
           (let ((,var ,handle-iter))
             ,@body)
         (when ,handle-iter
           (cl-indigo.cffi::%indigo-free ,handle-iter))))))

(defmacro with-catalysts-iterator ((var reaction) &body body)
  "Create catalysts iterator for REACTION with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-catalysts ,reaction)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-molecules-iterator ((var reader-or-array) &body body)
  "Create molecules iterator for READER-OR-ARRAY with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-molecules ,reader-or-array)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-matches-iterator ((var matcher query) &body body)
  "Create substructure matches iterator with automatic cleanup.
VAR is bound to the iterator handle within BODY."
  (with-gensyms (handle)
    `(let ((,handle (iterate-matches ,matcher ,query)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

(defmacro with-tautomers-iterator ((var molecule &optional options) &body body)
  "Create tautomers iterator for MOLECULE with automatic cleanup.
VAR is bound to the iterator handle within BODY.
OPTIONS is an options string (defaults to \"\")."
  (with-gensyms (handle)
    `(let ((,handle (iterate-tautomers ,molecule ,(or options ""))))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))

;;;; =========================================================================
;;;; Array Resource Macro
;;;; =========================================================================

(defmacro with-array ((var) &body body)
  "Create array with automatic cleanup.
VAR is bound to the array handle within BODY.
The array is automatically freed when BODY exits.

Example:
  (with-molecule* ((mol1 \"CCO\")
                   (mol2 \"c1ccccc1\"))
    (with-array (arr)
      (array-add arr mol1)
      (array-add arr mol2)))"
  (with-gensyms (handle)
    `(let ((,handle (create-array)))
       (unwind-protect
           (let ((,var ,handle))
             ,@body)
         (when ,handle
           (cl-indigo.cffi::%indigo-free ,handle))))))
