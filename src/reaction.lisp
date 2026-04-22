;;;; reaction.lisp - Reaction operations

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Reaction Operations
;;;; =========================================================================

;;; Note: Reaction loading is in mol/io.lisp (load-reaction-from-string, etc.)
;;; Note: Reaction iterators are in iter/iterators.lisp (iterate-reactants, etc.)
;;; Note: Reaction macros are in core/with-macros.lisp (with-reaction, etc.)

;;; This file is a placeholder for additional reaction-specific operations
;;; that may be added in the future, such as:
;;; - Atom mapping
;;; - Reaction center detection
;;; - Reaction normalization
;;; - AAM (atom-atom mapping) operations

;;; For now, basic reaction usage works via:
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
