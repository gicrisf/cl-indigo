# cl-indigo

Common Lisp bindings for the [Indigo](https://lifescience.opensource.epam.com/indigo/) cheminformatics toolkit.

## Key Features

**Molecular Operations**:
- Format conversions (SMILES, MOL, CML)
- Property calculations (molecular weight, formula, mass)
- Structure analysis (rings, stereocenters, bonds, atoms)
- Substructure matching and similarity searching
- Reaction processing and manipulation

**Advanced**:
- Iterator system for traversing molecular structures
- Lazy stream abstraction with functional combinators (`stream-map`, `stream-filter`, `stream-fold`)
- Fingerprint generation and similarity metrics (Tanimoto, Tversky, Euclidean)
- Chemical rendering to SVG, PNG, and PDF
- Automatic resource management via `with-*` macros

## Installation

### Requirements

Before lisp, you need:
- Indigo shared libraries
- GCC runtime libraries (`libstdc++`, `libgcc_s`)

To get indigo:

```bash
git clone https://github.com/gicrisf/cl-indigo.git
cd cl-indigo
./install-indigo.sh linux-x86_64
```

This downloads `libindigo.so` and `libindigo-renderer.so` from Ubuntu packages into `indigo-install/lib/`. Of course, you can also get those manually.

The renderer is optional but also requires:
- [Cairo](https://www.cairographics.org/)

About lisp, you need:
- Any Common Lisp implementation with CFFI support (only SBCL tested)
- [Quicklisp](https://quicklisp.org/)

If you have nix, you can simply load the right dependencies with:

```bash
nix-shell # in root
```

This sets `LD_LIBRARY_PATH` automatically to include `indigo-install/lib/` and `cairo`.

### Loading

```lisp
(load "~/quicklisp/setup.lisp")
(push #p"/path/to/cl-indigo/" asdf:*central-registry*)
(asdf:load-system :cl-indigo)
(use-package :cl-indigo)
```

### Post-installation

Verify the installation:

```lisp
(asdf:test-system :cl-indigo)
```

This runs the full test suite.

## Quick Start

### Basic Examples

Stateless convenience functions for one-off calculations:

```lisp
;; Get molecular properties from SMILES
(do-molecular-weight "CCO")          ; => 46.069
(do-molecular-formula "CCO")         ; => "C2 H6 O"
(do-canonical-smiles "CCO")          ; => "CCO"

;; Structure analysis
(do-atom-count "c1ccccc1")           ; => 6 (benzene)
(do-ring-count "c1ccccc1")           ; => 1

;; Substructure matching
(do-substructure-match "CCO" "[OH]") ; => T (ethanol contains OH)
(do-exact-match "CCO" "OCC")         ; => T (same molecule)

;; Hydrogen bond donors/acceptors
(do-hbd-count "CCO")                 ; => 1 (the OH group)
(do-hba-count "CCO")                 ; => 1 (the O)

;; Reaction processing
(do-reaction-reactants-count "CCO.CC>>CCOC")  ; => 2
(do-reaction-products-count "CCO.CC>>CCOC")   ; => 1
```

All `do-*` functions handle resource management automatically.

### Advanced Examples

The `with-*` macros provide automatic resource management for all Indigo objects, analogous to `with-open-file`. The `indigo-map` function lets you easily work with iterators:

```lisp
;; Analyze a molecule's structure
(with-molecule (mol "c1ccccc1")      ; Benzene
  (layout mol)                       ; Generate 2D coordinates
  (with-atoms-iterator (atoms mol)
    (indigo-map #'atom-symbol atoms)))
;; => ("C" "C" "C" "C" "C" "C")

;; Compare molecular weights of multiple molecules
(with-molecule* ((ethanol "CCO")
                 (benzene "c1ccccc1")
                 (propane "CCC"))
  (list (molecular-weight ethanol)
        (molecular-weight benzene)
        (molecular-weight propane)))
;; => (46.069 78.114 44.097)
```

**Sequential `*` variants**: Each macro has a `*` suffix version (e.g., `with-molecule*`) that works like `let*`, allowing multiple resources to be bound sequentially with proper cleanup even if later bindings fail:

```lisp
;; Compare two molecules
(with-molecule* ((mol1 "CCO")        ; Ethanol
                 (mol2 "CC(O)C"))    ; Isopropanol
  (with-fingerprint* ((fp1 mol1 "sim")
                      (fp2 mol2 "sim"))
    (similarity fp1 fp2 :tanimoto)))
;; => 0.714
```

### Available Macros

**Molecules**: `with-molecule`, `with-mol-file`, `with-query`, `with-smarts`
**Reactions**: `with-reaction`
**Iterators**: `with-atoms-iterator`, `with-bonds-iterator`, `with-neighbors-iterator`, `with-components-iterator`, `with-sssr-iterator`, `with-rings-iterator`, `with-subtrees-iterator`, `with-stereocenters-iterator`, `with-reactants-iterator`, `with-products-iterator`, `with-matches-iterator`, `with-tautomers-iterator`
**Fingerprints**: `with-fingerprint`
**Matchers**: `with-matcher`
**Arrays**: `with-array`
**Streams**: `with-atoms-stream`, `with-bonds-stream`, `with-components-stream`, `with-sssr-stream`, `with-rings-stream`, `with-subtrees-stream`, `with-stereocenters-stream`, `with-neighbors-stream`, `with-reactants-stream`, `with-products-stream`

### Lazy Streams

The stream abstraction provides functional, lazy evaluation over molecular iterators, with automatic element cleanup:

```lisp
;; Collect atom symbols using lazy streams
(with-molecule (mol "CCO")
  (with-atoms-stream (stream mol)
    (stream-collect (stream-map #'atom-symbol stream))))
;; => ("C" "C" "O")

;; Filter and transform
(with-molecule (mol "c1ccccc1CCCO")
  (with-atoms-stream (stream mol)
    (let* ((carbons (stream-filter
                     (lambda (atom) (string= (atom-symbol atom) "C"))
                     stream))
           (first-three (stream-take 3 carbons)))
      (stream-collect (stream-map #'atom-index first-three)))))
;; => (0 1 2)
```

Stream operations: `stream-first`, `stream-rest`, `stream-empty-p`, `stream-map`, `stream-filter`, `stream-take`, `stream-fold`, `stream-collect`

### Iterators

```lisp
;; Walk atoms manually
(with-molecule (mol "CCO")
  (with-atoms-iterator (atoms mol)
    (loop for atom = (indigo-next atoms)
          while atom
          collect (atom-symbol atom))))
;; => ("C" "C" "O")

;; Map over iterator with auto-cleanup
(with-molecule (mol "CCO")
  (with-atoms-iterator (atoms mol)
    (indigo-map #'atom-symbol atoms)))
;; => ("C" "C" "O")
```

### Atom and Bond Properties

```lisp
(with-molecule (mol "CCO")
  (layout mol)  ; Generate coordinates
  (with-atoms-stream (stream mol)
    (let ((first-atom (stream-first stream)))
      (list (atom-symbol first-atom)       ; => "C"
            (atom-index first-atom)        ; => 0
            (atom-charge first-atom)       ; => 0
            (atom-xyz first-atom)))))      ; => (x y z)
```

```lisp
(with-molecule (mol "C=C")  ; Ethene
  (with-bonds-stream (stream mol)
    (let ((first-bond (stream-first stream)))
      (list (bond-order first-bond)         ; => :DOUBLE
            (bond-source first-bond)        ; => atom handle
            (bond-destination first-bond)   ; => atom handle
            (bond-single-p first-bond)      ; => NIL
            (bond-double-p first-bond)))))  ; => T
```

Bond predicates: `bond-single-p`, `bond-double-p`, `bond-triple-p`, `bond-aromatic-p`, `bond-has-stereo-p`

### Molecular Properties

```lisp
(with-molecule (mol "c1ccccc1CCO")
  (list (canonical-smiles mol)       ; Canonical SMILES
        (smiles mol)                 ; Input-order SMILES
        (gross-formula mol)          ; => "C8H10O"
        (molecular-weight mol)       ; Float
        (monoisotopic-mass mol)      ; Exact mass
        (most-abundant-mass mol)     ; Abundant mass
        (molfile mol)                ; V2000 MOL string
        (cml mol)                    ; CML XML string
        (count-atoms mol)            ; => 9
        (count-bonds mol)            ; => 9
        (count-sssr mol)             ; => 1 (benzene ring)
        (count-stereocenters mol)))  ; => 0
```

### Structure Manipulation

```lisp
;; Layout (2D coordinate generation)
(with-molecule (mol "CCO")
  (layout mol)
  (has-coordinates mol))  ; => T

;; Aromaticity detection
(with-molecule (mol "C1=CC=CC=C1")  ; Kekulé benzene
  (aromatize mol)
  (canonical-smiles mol))  ; => "c1ccccc1"

;; Hydrogen management
(with-molecule (mol "CCO")
  (unfold-hydrogens mol)   ; Add explicit H atoms
  (count-atoms mol)        ; => 9 (3 heavy + 6 H)
  (fold-hydrogens mol)     ; Back to implicit
  (count-atoms mol))       ; => 3

;; Normalization / standardization
(with-molecule (mol "CCO")
  (normalize mol)
  (standardize mol)
  (ionize mol 7.4 1.0))  ; Physiological pH
```

### Substructure Matching and Similarity

```lisp
;; Check for benzene ring substructure
(with-molecule (mol "c1ccccc1CCO")
  (with-matcher (matcher mol)
    (with-query (query "c1ccccc1")
      (not (null (match matcher query))))))
;; => T

;; Exact match (different SMILES, same molecule)
(with-molecule* ((m1 "CCO") (m2 "OCC"))
  (exact-match m1 m2))
;; => T

;; Fingerprint similarity
(with-molecule* ((mol1 "CCO") (mol2 "CCC"))
  (with-fingerprint* ((fp1 mol1 "sim")
                      (fp2 mol2 "sim"))
    (similarity fp1 fp2)))
;; => ~0.6 (Tanimoto coefficient)
```

Similarity metrics: `:tanimoto` (default), `:euclid-sub`, `:tversky` (with alpha/beta params)

### Reactions

```lisp
(with-reaction (rxn "CCO.CC(=O)O>>CCOC(=O)C")  ; Esterification
  (with-reactants-iterator (reactants rxn)
    (indigo-map #'canonical-smiles reactants)))
;; => ("CCO" "CC(=O)O")

(with-reaction (rxn "CCO.CC(=O)O>>CCOC(=O)C")
  (with-products-iterator (products rxn)
    (indigo-map #'canonical-smiles products)))
;; => ("CCOC(=O)C")
```

### Rendering

Requires `libindigo-renderer.so` (loaded automatically with a warning if unavailable).

```lisp
;; Render to file
(with-molecule (mol "c1ccccc1")
  (layout mol)
  (set-option "render-output-format" "svg")
  (set-option-int "render-image-width" 400)
  (set-option-int "render-image-height" 300)
  (set-option-float "render-bond-length" 40.0)
  (render-to-file mol "benzene.svg"))

;; Render to buffer (in-memory)
(with-molecule (mol "c1ccccc1")
  (layout mol)
  (let ((writer (write-buffer)))
    (unwind-protect
        (progn
          (set-option "render-output-format" "svg")
          (render mol writer)
          (to-buffer writer))
      (indigo-free writer))))

;; Grid rendering (multiple molecules)
(let ((arr (create-array)))
  (with-molecule* ((mol1 "c1ccccc1")
                   (mol2 "CCO")
                   (mol3 "CC(=O)O"))
    (layout mol1) (layout mol2) (layout mol3)
    (array-add arr mol1)
    (array-add arr mol2)
    (array-add arr mol3)
    (render-grid-to-file arr nil 3 "grid.svg"))
  (indigo-free arr))
```

### Standalone Script

A ready-to-use rendering script is included:

```bash
./render-mol.sh "c1ccccc1" /tmp/benzene.svg
```

This loads `cl-indigo`, generates 2D coordinates, and renders to SVG.

## Configuration

Indigo options are set via `set-option` and typed variants:

```lisp
(set-option "render-output-format" "svg")            ; String option
(set-option-int "render-image-width" 400)             ; Integer option
(set-option-bool "render-highlight-thickness" 1)      ; Boolean option
(set-option-float "render-bond-length" 40.0)          ; Float option
(set-option-color "render-background-color" 1.0 1.0 1.0) ; RGB (0.0-1.0)
(set-option-xy "render-option-position" 100 200)      ; XY coordinate option
(render-reset)                                        ; Reset to defaults
```

## Architecture

```
cl-indigo.cffi (package)       — Raw CFFI bindings (% prefixed functions)
cl-indigo (package)            — High-level API, keyword-friendly
```

- **Handle-based**: All operations use integer handles (`signed-byte 32`), matching the Indigo C API directly
- **Two package system**: `cl-indigo.cffi` exposes low-level `%indigo-*` functions for advanced users; `cl-indigo` provides the user-facing API
- **Resource safety**: Every `with-*` macro uses `unwind-protect` for guaranteed cleanup on normal exit or error
- **Streams**: Lazy evaluation over iterators, implemented with a `lazy-stream` struct (memoized forcing), with functional combinators and automatic element cleanup via tracker functions

The API mirrors [emacs-indigo](https://github.com/gicrisf/emacs-indigo) adapted to Common Lisp conventions.

## Package API

### cl-indigo.cffi (low-level)

The `cl-indigo.cffi` package exports raw CFFI bindings prefixed with `%`:
- `%indigo-free`, `%indigo-clone`, `%indigo-version`
- `%indigo-load-molecule-from-string`, `%indigo-load-molecule-from-file`
- `%indigo-iterate-atoms`, `%indigo-iterate-bonds`, `%indigo-next`
- `%indigo-aromatize`, `%indigo-layout`, `%indigo-fold-hydrogens`
- `%indigo-fingerprint`, `%indigo-similarity`, `%indigo-substructure-matcher`
- `%indigo-render`, `%indigo-render-to-file`, `%indigo-render-grid`

Plus handle validation: `handle-valid-p`, `handle-error-p`, `handle-end-p`

### cl-indigo (high-level, user-facing)

All the examples in this README use the `cl-indigo` package. See the source files and `packages.lisp` for the full export list.

## License

GNU General Public License v3.0 or later. See LICENSE for details.
