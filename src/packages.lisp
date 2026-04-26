;;;; packages.lisp - Package definitions for cl-indigo

(defpackage #:cl-indigo.cffi
  (:use #:cl #:cffi)
  (:documentation "Low-level CFFI bindings for Indigo C library")
  (:export
   ;; Library loading
   #:load-indigo-library
   #:*indigo-loaded*

   ;; Type checking
   #:handle-valid-p
   #:handle-error-p
   #:handle-end-p

   ;; Raw CFFI functions (prefixed with %)
   #:%indigo-free
   #:%indigo-free-all-objects
   #:%indigo-clone
   #:%indigo-get-last-error
   #:%indigo-count-references
   #:%indigo-version

   ;; Session management
   #:%indigo-alloc-session-id
   #:%indigo-set-session-id
   #:%indigo-release-session-id

   ;; Molecule I/O
   #:%indigo-load-molecule-from-string
   #:%indigo-load-molecule-from-file
   #:%indigo-load-query-molecule-from-string
   #:%indigo-load-query-molecule-from-file
   #:%indigo-load-smarts-from-string
   #:%indigo-load-smarts-from-file
   #:%indigo-load-reaction-from-string
   #:%indigo-load-reaction-from-file

   ;; Molecule properties (strings)
   #:%indigo-canonical-smiles
   #:%indigo-smiles
   #:%indigo-molfile
   #:%indigo-cml
   #:%indigo-gross-formula
   #:%indigo-to-string

   ;; Molecule properties (numbers)
   #:%indigo-molecular-weight
   #:%indigo-most-abundant-mass
   #:%indigo-monoisotopic-mass
   #:%indigo-count-atoms
   #:%indigo-count-bonds
   #:%indigo-count-heavy-atoms
   #:%indigo-count-implicit-hydrogens
   #:%indigo-count-sssr
   #:%indigo-count-stereocenters

   ;; Atom properties
   #:%indigo-symbol
   #:%indigo-index
   #:%indigo-get-charge
   #:%indigo-get-radical
   #:%indigo-get-radical-electrons
   #:%indigo-xyz

   ;; Bond properties
   #:%indigo-source
   #:%indigo-destination
   #:%indigo-bond-order
   #:%indigo-bond-stereo

   ;; Iterators
   #:%indigo-next
   #:%indigo-iterate-atoms
   #:%indigo-iterate-bonds
   #:%indigo-iterate-neighbors
   #:%indigo-iterate-components
   #:%indigo-iterate-sssr
   #:%indigo-iterate-stereocenters
   #:%indigo-iterate-reactants
   #:%indigo-iterate-products
   #:%indigo-iterate-array
   #:%indigo-iterate-matches
   #:%indigo-iterate-tautomers

   ;; Structure manipulation
   #:%indigo-aromatize
   #:%indigo-layout
   #:%indigo-fold-hydrogens
   #:%indigo-unfold-hydrogens
   #:%indigo-normalize
   #:%indigo-standardize
   #:%indigo-ionize

   ;; Matching
   #:%indigo-fingerprint
   #:%indigo-similarity
   #:%indigo-substructure-matcher
   #:%indigo-exact-match
   #:%indigo-match

   ;; Coordinates
   #:%indigo-has-coordinates
   #:%indigo-has-z-coord
   #:%indigo-is-chiral

   ;; Reaction mapping
   #:%indigo-automap
   #:%indigo-get-atom-mapping-number
   #:%indigo-set-atom-mapping-number
   #:%indigo-clear-aam
   #:%indigo-correct-reacting-centers
   #:%indigo-get-reacting-center
   #:%indigo-set-reacting-center
   #:%indigo-count-reactants
   #:%indigo-count-products

   ;; PKA calculations
   #:%indigo-build-pka-model
   #:%indigo-get-acid-pka-value
   #:%indigo-get-basic-pka-value

   ;; Rendering
   #:%indigo-render
   #:%indigo-render-to-file
   #:%indigo-render-grid
   #:%indigo-render-grid-to-file
   #:%indigo-render-reset
   #:%indigo-write-buffer
   #:%indigo-to-buffer
   #:%indigo-to-string
   #:%indigo-create-array
   #:%indigo-array-add
   #:%indigo-iterate-array))

(defpackage #:cl-indigo
  (:use #:cl)
  (:import-from #:alexandria #:with-gensyms #:once-only)
  (:documentation "High-level Common Lisp interface to Indigo cheminformatics")
  (:export
   ;; Conditions
   #:indigo-error
   #:indigo-error-message

   ;; System
   #:indigo-version
   #:count-references
   #:get-last-error
   #:free-all-objects

   ;; Session management
   #:alloc-session-id
   #:set-session-id
   #:release-session-id

   ;; Options
   #:set-option
   #:set-option-int
   #:set-option-bool
   #:set-option-float
   #:set-option-color
   #:set-option-xy

   ;; Resource management macros (molecules)
   #:with-molecule
   #:with-molecule*
   #:with-mol-file
   #:with-mol-file*
   #:with-query
   #:with-query*
   #:with-smarts
   #:with-smarts*
   #:with-fingerprint
   #:with-fingerprint*
   #:with-matcher
   #:with-matcher*
   #:with-reaction
   #:with-reaction*
   #:with-rxn-file
   #:with-rxn-file*

   ;; Resource management macros (iterators)
   #:with-atoms-iterator
   #:with-atoms-iterator*
   #:with-bonds-iterator
   #:with-bonds-iterator*
   #:with-neighbors-iterator
   #:with-neighbors-iterator*
   #:with-components-iterator
   #:with-components-iterator*
   #:with-sssr-iterator
   #:with-sssr-iterator*
   #:with-stereocenters-iterator
   #:with-stereocenters-iterator*
   #:with-reactants-iterator
   #:with-reactants-iterator*
   #:with-products-iterator
   #:with-products-iterator*
   #:with-subtrees-iterator
   #:with-rings-iterator
   #:with-edge-submolecules-iterator
   #:with-properties-iterator
   #:with-catalysts-iterator
   #:with-molecules-iterator
   #:with-matches-iterator
   #:with-tautomers-iterator

   ;; Resource management macros (streams)
   #:with-atoms-stream
   #:with-atoms-stream*
   #:with-bonds-stream
   #:with-bonds-stream*
   #:with-components-stream
   #:with-sssr-stream
   #:with-rings-stream
   #:with-subtrees-stream
   #:with-stereocenters-stream
   #:with-neighbors-stream
   #:with-reactants-stream
   #:with-products-stream
   #:with-stream-from-iterator

   ;; Stream operations
   #:indigo-stream
   #:lazy-stream-p
   #:stream-force
   #:stream-first
   #:stream-rest
   #:stream-empty-p
   #:stream-map
   #:stream-filter
   #:stream-take
   #:stream-fold
   #:stream-collect

   ;; Molecule I/O
   #:load-molecule-from-string
   #:load-molecule-from-file
   #:load-query-molecule-from-string
   #:load-query-molecule-from-file
   #:load-smarts-from-string
   #:load-smarts-from-file
   #:load-reaction-from-string
   #:load-reaction-from-file

   ;; Molecular properties
   #:molecular-weight
   #:most-abundant-mass
   #:monoisotopic-mass
   #:canonical-smiles
   #:smiles
   #:molfile
   #:cml
   #:gross-formula
   #:count-atoms
   #:count-bonds
   #:count-heavy-atoms
   #:count-implicit-hydrogens
   #:count-sssr
   #:count-stereocenters
   #:has-coordinates
   #:has-z-coord
   #:is-chiral

   ;; Atom properties
   #:atom-symbol
   #:atom-index
   #:atom-charge
   #:atom-radical
   #:atom-radical-electrons
   #:atom-xyz
   #:atom-radical-p
   #:atom-singlet-p
   #:atom-doublet-p
   #:atom-triplet-p

   ;; Bond properties
   #:bond-order
   #:bond-stereo
   #:bond-source
   #:bond-destination
   #:bond-single-p
   #:bond-double-p
   #:bond-triple-p
   #:bond-aromatic-p
   #:bond-has-stereo-p

   ;; Enums
   #:+bond-orders+
   #:+bond-stereos+
   #:+radicals+
   #:bond-order-keyword
   #:bond-order-code
   #:bond-stereo-keyword
   #:bond-stereo-code
   #:radical-keyword
   #:radical-code

   ;; Structure manipulation
   #:aromatize
   #:layout
   #:fold-hydrogens
   #:unfold-hydrogens
   #:normalize
   #:standardize
   #:ionize

   ;; Iterator functions
   #:iterate-atoms
   #:iterate-bonds
   #:iterate-neighbors
   #:iterate-components
   #:iterate-sssr
   #:iterate-stereocenters
   #:iterate-reactants
   #:iterate-products
   #:iterate-subtrees
   #:iterate-rings
   #:iterate-edge-submolecules
   #:iterate-properties
   #:iterate-catalysts
   #:iterate-molecules
   #:iterate-matches
   #:iterate-tautomers
   #:indigo-next
   #:indigo-map

   ;; Matching
   #:fingerprint
   #:similarity
   #:substructure-matcher
   #:exact-match

   ;; Rendering
   #:render-to-file
   #:write-buffer
   #:to-buffer
   #:render
   #:render-grid
   #:render-grid-to-file
   #:render-reset
   #:create-array
   #:array-add
   #:iterate-array
   #:with-array

   ;; Molecule creation
   #:create-molecule
   #:create-query-molecule

   ;; Molecule saving
   #:save-molfile-to-file

   ;; Reaction operations
   #:automap
   #:get-atom-mapping-number
   #:set-atom-mapping-number
   #:clear-aam
   #:correct-reacting-centers
   #:get-reacting-center
   #:set-reacting-center
   #:count-reactants
   #:count-products

   ;; PKA calculations
   #:build-pka-model
   #:get-acid-pka-value
   #:get-basic-pka-value

   ;; Low-level
   #:indigo-free
   #:indigo-clone

   ;; Stateless functions (auto-cleanup convenience wrappers)
   #:do-molecular-formula
   #:do-molecular-weight
   #:do-most-abundant-mass
   #:do-monoisotopic-mass
   #:do-canonical-smiles
   #:do-smiles
   #:do-molfile
   #:do-cml
   #:do-atom-count
   #:do-bond-count
   #:do-heavy-atom-count
   #:do-hydrogen-count
   #:do-total-atom-count
   #:do-ring-count
   #:do-aromatic-ring-count
   #:do-chiral-center-count
   #:do-formal-charge
   #:do-hbd-count
   #:do-hba-count
   #:do-has-stereochemistry
   #:do-is-chiral
   #:do-has-coordinates
   #:do-has-z-coord
   #:do-substructure-match
   #:do-exact-match
   #:do-similarity
   #:do-reaction-products-count
   #:do-reaction-reactants-count
   #:do-layered-code))
