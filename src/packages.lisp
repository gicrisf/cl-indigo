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

   ;; Rendering
   #:%indigo-render-to-file
   #:%indigo-create-array
   #:%indigo-array-add))

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

   ;; Resource management macros (streams)
   #:with-atoms-stream
   #:with-atoms-stream*
   #:with-bonds-stream
   #:with-bonds-stream*
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
   #:indigo-next
   #:indigo-map

   ;; Matching
   #:fingerprint
   #:similarity
   #:substructure-matcher
   #:exact-match

   ;; Rendering
   #:render-to-file
   #:create-array
   #:array-add

   ;; Molecule creation
   #:create-molecule
   #:create-query-molecule

   ;; Molecule saving
   #:save-molfile-to-file

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
