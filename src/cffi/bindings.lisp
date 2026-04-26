;;;; bindings.lisp - CFFI function bindings for Indigo

(in-package #:cl-indigo.cffi)

;;; Ensure library is loaded when this file is loaded
(eval-when (:load-toplevel :execute)
  (load-indigo-library))

;;;; =========================================================================
;;;; Core Functions
;;;; =========================================================================

;;; Memory Management

(defcfun ("indigoFree" %indigo-free) :int
  "Free an Indigo object handle."
  (handle :int))

(defcfun ("indigoFreeAllObjects" %indigo-free-all-objects) :int
  "Free all Indigo objects in current session.")

(defcfun ("indigoClone" %indigo-clone) :int
  "Clone an Indigo object."
  (handle :int))

;;; Error Handling

(defcfun ("indigoGetLastError" %indigo-get-last-error) (:string :encoding :latin-1)
  "Get the last error message from Indigo.
Uses Latin-1 encoding to safely handle any byte sequence Indigo may return.")

;;; System Functions

(defcfun ("indigoVersion" %indigo-version) :string
  "Get Indigo version string.")

(defcfun ("indigoCountReferences" %indigo-count-references) :int
  "Count objects currently allocated in session.")

;;; Session Management

(defcfun ("indigoAllocSessionId" %indigo-alloc-session-id) :unsigned-long-long
  "Allocate a new session ID.")

(defcfun ("indigoSetSessionId" %indigo-set-session-id) :void
  "Set the current session ID."
  (session-id :unsigned-long-long))

(defcfun ("indigoReleaseSessionId" %indigo-release-session-id) :void
  "Release a session ID."
  (session-id :unsigned-long-long))

;;;; =========================================================================
;;;; Molecule I/O
;;;; =========================================================================

;;; Loading from strings

(defcfun ("indigoLoadMoleculeFromString" %indigo-load-molecule-from-string) :int
  "Load molecule from string (SMILES, MOL, etc.)."
  (string :string))

(defcfun ("indigoLoadQueryMoleculeFromString" %indigo-load-query-molecule-from-string) :int
  "Load query molecule from string."
  (string :string))

(defcfun ("indigoLoadSmartsFromString" %indigo-load-smarts-from-string) :int
  "Load SMARTS pattern from string."
  (string :string))

(defcfun ("indigoLoadReactionFromString" %indigo-load-reaction-from-string) :int
  "Load reaction from string."
  (string :string))

;;; Loading from files

(defcfun ("indigoLoadMoleculeFromFile" %indigo-load-molecule-from-file) :int
  "Load molecule from file."
  (filename :string))

(defcfun ("indigoLoadQueryMoleculeFromFile" %indigo-load-query-molecule-from-file) :int
  "Load query molecule from file."
  (filename :string))

(defcfun ("indigoLoadSmartsFromFile" %indigo-load-smarts-from-file) :int
  "Load SMARTS pattern from file."
  (filename :string))

(defcfun ("indigoLoadReactionFromFile" %indigo-load-reaction-from-file) :int
  "Load reaction from file."
  (filename :string))

;;; Loading from buffers

(defcfun ("indigoLoadMoleculeFromBuffer" %indigo-load-molecule-from-buffer) :int
  "Load molecule from buffer."
  (buffer (:pointer :char))
  (size :int))

(defcfun ("indigoLoadQueryMoleculeFromBuffer" %indigo-load-query-molecule-from-buffer) :int
  "Load query molecule from buffer."
  (buffer (:pointer :char))
  (size :int))

(defcfun ("indigoLoadSmartsFromBuffer" %indigo-load-smarts-from-buffer) :int
  "Load SMARTS pattern from buffer."
  (buffer (:pointer :char))
  (size :int))

;;; Molecule creation

(defcfun ("indigoCreateMolecule" %indigo-create-molecule) :int
  "Create empty molecule.")

(defcfun ("indigoCreateQueryMolecule" %indigo-create-query-molecule) :int
  "Create empty query molecule.")

;;; Saving molecules

(defcfun ("indigoSaveMolfileToFile" %indigo-save-molfile-to-file) :int
  "Save molecule to MOL file."
  (molecule :int)
  (filename :string))

;;;; =========================================================================
;;;; Molecule Properties (String Returns)
;;;; =========================================================================

(defcfun ("indigoCanonicalSmiles" %indigo-canonical-smiles) :string
  "Get canonical SMILES from molecule."
  (molecule :int))

(defcfun ("indigoSmiles" %indigo-smiles) :string
  "Get SMILES from molecule."
  (molecule :int))

(defcfun ("indigoMolfile" %indigo-molfile) :string
  "Get MOL file format from molecule."
  (molecule :int))

(defcfun ("indigoCml" %indigo-cml) :string
  "Get CML format from molecule."
  (molecule :int))

(defcfun ("indigoGrossFormula" %indigo-gross-formula) :int
  "Get gross formula object (use indigo-to-string to get string)."
  (molecule :int))

(defcfun ("indigoToString" %indigo-to-string) :string
  "Convert Indigo object to string."
  (handle :int))

;;;; =========================================================================
;;;; Molecule Properties (Numeric Returns)
;;;; =========================================================================

(defcfun ("indigoMolecularWeight" %indigo-molecular-weight) :double
  "Get molecular weight."
  (molecule :int))

(defcfun ("indigoMostAbundantMass" %indigo-most-abundant-mass) :double
  "Get most abundant mass."
  (molecule :int))

(defcfun ("indigoMonoisotopicMass" %indigo-monoisotopic-mass) :double
  "Get monoisotopic mass."
  (molecule :int))

(defcfun ("indigoCountAtoms" %indigo-count-atoms) :int
  "Get atom count."
  (molecule :int))

(defcfun ("indigoCountBonds" %indigo-count-bonds) :int
  "Get bond count."
  (molecule :int))

(defcfun ("indigoCountHeavyAtoms" %indigo-count-heavy-atoms) :int
  "Get heavy atom count."
  (molecule :int))

(defcfun ("indigoCountImplicitHydrogens" %indigo-count-implicit-hydrogens) :int
  "Get implicit hydrogen count."
  (handle :int))

(defcfun ("indigoCountSSSR" %indigo-count-sssr) :int
  "Get SSSR ring count."
  (molecule :int))

(defcfun ("indigoCountStereocenters" %indigo-count-stereocenters) :int
  "Get stereocenter count."
  (molecule :int))

(defcfun ("indigoHasCoord" %indigo-has-coordinates) :int
  "Check if molecule has 2D/3D coordinates."
  (molecule :int))

(defcfun ("indigoHasZCoord" %indigo-has-z-coord) :int
  "Check if molecule has 3D coordinates."
  (molecule :int))

;;; Advanced molecular properties

(defcfun ("indigoIsChiral" %indigo-is-chiral) :int
  "Check if molecule is chiral."
  (molecule :int))

(defcfun ("indigoLayeredCode" %indigo-layered-code) :string
  "Get layered code for molecule."
  (molecule :int))

(defcfun ("indigoSymmetryClasses" %indigo-symmetry-classes) :int
  "Get symmetry classes object."
  (molecule :int)
  (buffer (:pointer :int)))

(defcfun ("indigoStereocenterType" %indigo-stereocenter-type) :int
  "Get stereocenter type."
  (atom :int))

(defcfun ("indigoCountHydrogens" %indigo-count-hydrogens) :int
  "Get total hydrogen count (explicit + implicit)."
  (atom :int)
  (hydrogen-count (:pointer :int)))

(defcfun ("indigoCountReactants" %indigo-count-reactants) :int
  "Get reactant count in reaction."
  (reaction :int))

(defcfun ("indigoCountProducts" %indigo-count-products) :int
  "Get product count in reaction."
  (reaction :int))

;;;; =========================================================================
;;;; Atom Properties
;;;; =========================================================================

(defcfun ("indigoSymbol" %indigo-symbol) :string
  "Get atom element symbol."
  (atom :int))

(defcfun ("indigoIndex" %indigo-index) :int
  "Get index of atom/bond/etc."
  (item :int))

(defcfun ("indigoGetCharge" %indigo-get-charge) :int
  "Get atom formal charge (output parameter)."
  (atom :int)
  (charge (:pointer :int)))

(defcfun ("indigoGetRadical" %indigo-get-radical) :int
  "Get atom radical state (output parameter)."
  (atom :int)
  (radical (:pointer :int)))

(defcfun ("indigoGetRadicalElectrons" %indigo-get-radical-electrons) :int
  "Get atom radical electrons (output parameter)."
  (atom :int)
  (electrons (:pointer :int)))

(defcfun ("indigoXYZ" %indigo-xyz) (:pointer :float)
  "Get atom XYZ coordinates (returns pointer to 3 floats)."
  (atom :int))

;;;; =========================================================================
;;;; Bond Properties
;;;; =========================================================================

(defcfun ("indigoSource" %indigo-source) :int
  "Get source atom handle of bond."
  (bond :int))

(defcfun ("indigoDestination" %indigo-destination) :int
  "Get destination atom handle of bond."
  (bond :int))

(defcfun ("indigoBondOrder" %indigo-bond-order) :int
  "Get bond order (1=single, 2=double, 3=triple, 4=aromatic)."
  (bond :int))

(defcfun ("indigoBondStereo" %indigo-bond-stereo) :int
  "Get bond stereochemistry."
  (bond :int))

;;;; =========================================================================
;;;; Iterators
;;;; =========================================================================

(defcfun ("indigoNext" %indigo-next) :int
  "Get next item from iterator. Returns 0 when exhausted, -1 on error."
  (iterator :int))

(defcfun ("indigoIterateAtoms" %indigo-iterate-atoms) :int
  "Create iterator over atoms in molecule."
  (molecule :int))

(defcfun ("indigoIterateBonds" %indigo-iterate-bonds) :int
  "Create iterator over bonds in molecule."
  (molecule :int))

(defcfun ("indigoIterateNeighbors" %indigo-iterate-neighbors) :int
  "Create iterator over neighbors of an atom."
  (atom :int))

(defcfun ("indigoIterateComponents" %indigo-iterate-components) :int
  "Create iterator over connected components."
  (molecule :int))

(defcfun ("indigoIterateSSSR" %indigo-iterate-sssr) :int
  "Create iterator over SSSR rings."
  (molecule :int))

(defcfun ("indigoIterateStereocenters" %indigo-iterate-stereocenters) :int
  "Create iterator over stereocenters."
  (molecule :int))

(defcfun ("indigoIterateReactants" %indigo-iterate-reactants) :int
  "Create iterator over reaction reactants."
  (reaction :int))

(defcfun ("indigoIterateProducts" %indigo-iterate-products) :int
  "Create iterator over reaction products."
  (reaction :int))

;;; Advanced iterators

(defcfun ("indigoIterateSubtrees" %indigo-iterate-subtrees) :int
  "Create iterator over subtrees."
  (molecule :int)
  (min-vertices :int)
  (max-vertices :int))

(defcfun ("indigoIterateRings" %indigo-iterate-rings) :int
  "Create iterator over rings."
  (molecule :int)
  (min-vertices :int)
  (max-vertices :int))

(defcfun ("indigoIterateEdgeSubmolecules" %indigo-iterate-edge-submolecules) :int
  "Create iterator over edge submolecules."
  (molecule :int)
  (min-bonds :int)
  (max-bonds :int))

(defcfun ("indigoIteratePseudoatoms" %indigo-iterate-pseudoatoms) :int
  "Create iterator over pseudoatoms."
  (molecule :int))

(defcfun ("indigoIterateRSites" %indigo-iterate-rsites) :int
  "Create iterator over R-sites."
  (molecule :int))

(defcfun ("indigoIterateAlleneCenters" %indigo-iterate-allene-centers) :int
  "Create iterator over allene centers."
  (molecule :int))

(defcfun ("indigoIterateRGroups" %indigo-iterate-rgroups) :int
  "Create iterator over R-groups."
  (molecule :int))

(defcfun ("indigoIterateRGroupFragments" %indigo-iterate-rgroup-fragments) :int
  "Create iterator over R-group fragments."
  (rgroup :int))

(defcfun ("indigoIterateAttachmentPoints" %indigo-iterate-attachment-points) :int
  "Create iterator over attachment points."
  (item :int)
  (order :int))

(defcfun ("indigoIterateDataSGroups" %indigo-iterate-data-sgroups) :int
  "Create iterator over data S-groups."
  (molecule :int))

(defcfun ("indigoIterateSuperatoms" %indigo-iterate-superatoms) :int
  "Create iterator over superatoms."
  (molecule :int))

(defcfun ("indigoIterateGenericSGroups" %indigo-iterate-generic-sgroups) :int
  "Create iterator over generic S-groups."
  (molecule :int))

(defcfun ("indigoIterateRepeatingUnits" %indigo-iterate-repeating-units) :int
  "Create iterator over repeating units."
  (molecule :int))

(defcfun ("indigoIterateMultipleGroups" %indigo-iterate-multiple-groups) :int
  "Create iterator over multiple groups."
  (molecule :int))

(defcfun ("indigoIterateProperties" %indigo-iterate-properties) :int
  "Create iterator over properties."
  (handle :int))

(defcfun ("indigoIterateCatalysts" %indigo-iterate-catalysts) :int
  "Create iterator over reaction catalysts."
  (reaction :int))

(defcfun ("indigoIterateMolecules" %indigo-iterate-molecules) :int
  "Create iterator over molecules in file reader/array."
  (reader-or-array :int))

(defcfun ("indigoIterateArray" %indigo-iterate-array) :int
  "Create iterator over array."
  (array :int))

(defcfun ("indigoIterateMatches" %indigo-iterate-matches) :int
  "Create iterator over substructure matches."
  (matcher :int)
  (query :int))

(defcfun ("indigoIterateTautomers" %indigo-iterate-tautomers) :int
  "Create iterator over tautomers."
  (molecule :int)
  (params :string))

(defcfun ("indigoIterateDecomposedMolecules" %indigo-iterate-decomposed-molecules) :int
  "Create iterator over decomposed molecules."
  (scaffold :int)
  (structures :int))

(defcfun ("indigoIterateDecompositions" %indigo-iterate-decompositions) :int
  "Create iterator over decompositions."
  (molecule :int)
  (scaffold :int))

;;;; =========================================================================
;;;; Structure Manipulation
;;;; =========================================================================

(defcfun ("indigoAromatize" %indigo-aromatize) :int
  "Aromatize molecule (detect and mark aromatic rings)."
  (molecule :int))

(defcfun ("indigoLayout" %indigo-layout) :int
  "Calculate 2D coordinates for molecule."
  (molecule :int))

(defcfun ("indigoFoldHydrogens" %indigo-fold-hydrogens) :int
  "Remove explicit hydrogens (convert to implicit)."
  (molecule :int))

(defcfun ("indigoUnfoldHydrogens" %indigo-unfold-hydrogens) :int
  "Add explicit hydrogens."
  (molecule :int))

(defcfun ("indigoNormalize" %indigo-normalize) :int
  "Normalize molecule structure."
  (molecule :int)
  (options :string))

(defcfun ("indigoStandardize" %indigo-standardize) :int
  "Standardize molecule charges, stereo, etc."
  (molecule :int))

(defcfun ("indigoIonize" %indigo-ionize) :int
  "Ionize molecule at specified pH."
  (molecule :int)
  (ph :float)
  (ph-tolerance :float))

;;;; =========================================================================
;;;; Matching and Fingerprints
;;;; =========================================================================

(defcfun ("indigoFingerprint" %indigo-fingerprint) :int
  "Generate fingerprint for molecule."
  (object :int)
  (type :string))

(defcfun ("indigoSimilarity" %indigo-similarity) :float
  "Calculate similarity between two fingerprints."
  (fp1 :int)
  (fp2 :int)
  (metrics :string))

(defcfun ("indigoSubstructureMatcher" %indigo-substructure-matcher) :int
  "Create substructure matcher for target molecule."
  (target :int))

(defcfun ("indigoExactMatch" %indigo-exact-match) :int
  "Check exact match between molecules."
  (mol1 :int)
  (mol2 :int)
  (flags :string))

(defcfun ("indigoMatch" %indigo-match) :int
  "Match query against matcher."
  (matcher :int)
  (query :int))

;;;; =========================================================================
;;;; Rendering
;;;; =========================================================================

(defcfun ("indigoRender" %indigo-render) :int
  "Render object to buffer."
  (object :int)
  (renderer :int))

(defcfun ("indigoRenderToFile" %indigo-render-to-file) :int
  "Render object to file."
  (object :int)
  (filename :string))

(defcfun ("indigoRenderGrid" %indigo-render-grid) :int
  "Render grid of objects."
  (array :int)
  (ref-atoms (:pointer :int))
  (n-columns :int)
  (renderer :int))

(defcfun ("indigoRenderGridToFile" %indigo-render-grid-to-file) :int
  "Render grid of objects to file."
  (array :int)
  (ref-atoms (:pointer :int))
  (n-columns :int)
  (filename :string))

(defcfun ("indigoRenderReset" %indigo-render-reset) :int
  "Reset renderer to default settings.")

;;;; =========================================================================
;;;; I/O and Buffers
;;;; =========================================================================

(defcfun ("indigoWriteFile" %indigo-write-file) :int
  "Write object to file."
  (filename :string))

(defcfun ("indigoWriteBuffer" %indigo-write-buffer) :int
  "Create a buffer writer.")

(defcfun ("indigoToBuffer" %indigo-to-buffer) :int
  "Convert object to buffer."
  (handle :int)
  (buf (:pointer (:pointer :char)))
  (size (:pointer :int)))

(defcfun ("indigoCreateArray" %indigo-create-array) :int
  "Create array for multiple objects.")

(defcfun ("indigoArrayAdd" %indigo-array-add) :int
  "Add object to array."
  (array :int)
  (object :int))

;;;; =========================================================================
;;;; Reaction Mapping
;;;; =========================================================================

(defcfun ("indigoAutomap" %indigo-automap) :int
  "Automatically map reaction atoms."
  (reaction :int)
  (mode :string))

(defcfun ("indigoGetAtomMappingNumber" %indigo-get-atom-mapping-number) :int
  "Get atom mapping number in reaction."
  (reaction :int)
  (atom :int))

(defcfun ("indigoSetAtomMappingNumber" %indigo-set-atom-mapping-number) :int
  "Set atom mapping number in reaction."
  (reaction :int)
  (atom :int)
  (number :int))

(defcfun ("indigoClearAAM" %indigo-clear-aam) :int
  "Clear atom-to-atom mapping in reaction."
  (reaction :int))

(defcfun ("indigoCorrectReactingCenters" %indigo-correct-reacting-centers) :int
  "Correct reacting centers in reaction."
  (reaction :int))

(defcfun ("indigoGetReactingCenter" %indigo-get-reacting-center) :int
  "Get reacting center type."
  (reaction :int)
  (bond :int)
  (rc (:pointer :int)))

(defcfun ("indigoSetReactingCenter" %indigo-set-reacting-center) :int
  "Set reacting center type."
  (reaction :int)
  (bond :int)
  (rc :int))

;;;; =========================================================================
;;;; PKA Calculations
;;;; =========================================================================

(defcfun ("indigoBuildPkaModel" %indigo-build-pka-model) :int
  "Build pKa prediction model."
  (level :int)
  (threshold :float)
  (filename :string))

(defcfun ("indigoGetAcidPkaValue" %indigo-get-acid-pka-value) :int
  "Get acidic pKa value."
  (atom :int)
  (level :int)
  (min-level :int)
  (pka (:pointer :float)))

(defcfun ("indigoGetBasicPkaValue" %indigo-get-basic-pka-value) :int
  "Get basic pKa value."
  (atom :int)
  (level :int)
  (min-level :int)
  (pka (:pointer :float)))

;;;; =========================================================================
;;;; Option Setting
;;;; =========================================================================

(defcfun ("indigoSetOption" %indigo-set-option) :int
  "Set string option."
  (name :string)
  (value :string))

(defcfun ("indigoSetOptionInt" %indigo-set-option-int) :int
  "Set integer option."
  (name :string)
  (value :int))

(defcfun ("indigoSetOptionBool" %indigo-set-option-bool) :int
  "Set boolean option."
  (name :string)
  (value :int))

(defcfun ("indigoSetOptionFloat" %indigo-set-option-float) :int
  "Set float option."
  (name :string)
  (value :float))

(defcfun ("indigoSetOptionColor" %indigo-set-option-color) :int
  "Set color option (RGB)."
  (name :string)
  (r :float)
  (g :float)
  (b :float))

(defcfun ("indigoSetOptionXY" %indigo-set-option-xy) :int
  "Set XY coordinate option."
  (name :string)
  (x :int)
  (y :int))
