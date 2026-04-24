;;;; properties.lisp - Molecular property functions

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; System Functions
;;;; =========================================================================

(defun indigo-version ()
  "Get Indigo library version string."
  (cl-indigo.cffi::%indigo-version))

(defun count-references ()
  "Count objects currently allocated in session.
Useful for debugging resource leaks."
  (cl-indigo.cffi::%indigo-count-references))

(defun get-last-error ()
  "Get the last error message from Indigo.
Returns the error message as a string."
  (cl-indigo.cffi::%indigo-get-last-error))

(defun free-all-objects ()
  "Free all Indigo objects in current session.
Returns 0 on success.
WARNING: This invalidates ALL handles in the current session."
  (cl-indigo.cffi::%indigo-free-all-objects))

;;;; =========================================================================
;;;; Session Management
;;;; =========================================================================

(defun alloc-session-id ()
  "Allocate a new session ID.
Returns session ID (positive integer) on success."
  (cl-indigo.cffi::%indigo-alloc-session-id))

(defun set-session-id (session-id)
  "Set the current session ID.
Returns T on success."
  (cl-indigo.cffi::%indigo-set-session-id session-id)
  t)

(defun release-session-id (session-id)
  "Release a session ID.
Returns T on success."
  (cl-indigo.cffi::%indigo-release-session-id session-id)
  t)

;;;; =========================================================================
;;;; Option Setting
;;;; =========================================================================

(defun set-option (name value)
  "Set Indigo string option NAME to VALUE.
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option name value))

(defun set-option-int (name value)
  "Set Indigo integer option NAME to VALUE.
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option-int name value))

(defun set-option-bool (name value)
  "Set Indigo boolean option NAME to VALUE (0 or 1).
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option-bool name value))

(defun set-option-float (name value)
  "Set Indigo float option NAME to VALUE.
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option-float name (coerce value 'single-float)))

(defun set-option-color (name r g b)
  "Set Indigo color option NAME to RGB values (0.0-1.0).
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option-color name
                                             (coerce r 'single-float)
                                             (coerce g 'single-float)
                                             (coerce b 'single-float)))

(defun set-option-xy (name x y)
  "Set Indigo XY option NAME to coordinates.
Returns result code (0 on success, negative on error)."
  (cl-indigo.cffi::%indigo-set-option-xy name x y))

;;;; =========================================================================
;;;; Format Conversions (String Output)
;;;; =========================================================================

(defun canonical-smiles (molecule)
  "Get canonical SMILES from MOLECULE handle.

Example:
  (with-molecule (mol \"CCO\")
    (canonical-smiles mol))
  => \"CCO\" or \"OCC\""
  (cl-indigo.cffi::%indigo-canonical-smiles molecule))

(defun smiles (molecule)
  "Get SMILES from MOLECULE handle.
Unlike canonical-smiles, preserves input atom ordering."
  (cl-indigo.cffi::%indigo-smiles molecule))

(defun molfile (molecule)
  "Get MOL file format from MOLECULE handle.
Returns the molecule in V2000 MOL format as a string."
  (cl-indigo.cffi::%indigo-molfile molecule))

(defun cml (molecule)
  "Get CML (Chemical Markup Language) from MOLECULE handle."
  (cl-indigo.cffi::%indigo-cml molecule))

(defun gross-formula (molecule)
  "Get gross formula from MOLECULE handle.
Returns formula like \"C2H6O\" as a string.

Example:
  (with-molecule (mol \"CCO\")
    (gross-formula mol))
  => \"C2H6O\""
  (let ((formula-handle (cl-indigo.cffi::%indigo-gross-formula molecule)))
    (when (cl-indigo.cffi::handle-valid-p formula-handle)
      (unwind-protect
          (cl-indigo.cffi::%indigo-to-string formula-handle)
        (cl-indigo.cffi::%indigo-free formula-handle)))))

;;;; =========================================================================
;;;; Numeric Properties
;;;; =========================================================================

(defun molecular-weight (molecule)
  "Get molecular weight from MOLECULE handle.
Returns weight in daltons as a float.

Example:
  (with-molecule (mol \"CCO\")
    (molecular-weight mol))
  => 46.069"
  (cl-indigo.cffi::%indigo-molecular-weight molecule))

(defun most-abundant-mass (molecule)
  "Get most abundant mass from MOLECULE handle.
This is the mass using the most common isotope for each element."
  (cl-indigo.cffi::%indigo-most-abundant-mass molecule))

(defun monoisotopic-mass (molecule)
  "Get monoisotopic mass from MOLECULE handle.
This is the exact mass using the lightest isotope for each element."
  (cl-indigo.cffi::%indigo-monoisotopic-mass molecule))

;;;; =========================================================================
;;;; Counting Functions
;;;; =========================================================================

(defun count-atoms (molecule)
  "Get atom count from MOLECULE handle.
Returns count of heavy atoms (non-hydrogen).

Example:
  (with-molecule (mol \"CCO\")
    (count-atoms mol))
  => 3"
  (cl-indigo.cffi::%indigo-count-atoms molecule))

(defun count-bonds (molecule)
  "Get bond count from MOLECULE handle.

Example:
  (with-molecule (mol \"CCO\")
    (count-bonds mol))
  => 2"
  (cl-indigo.cffi::%indigo-count-bonds molecule))

(defun count-heavy-atoms (molecule)
  "Get heavy atom count from MOLECULE handle.
Heavy atoms are all atoms except hydrogen."
  (cl-indigo.cffi::%indigo-count-heavy-atoms molecule))

(defun count-implicit-hydrogens (handle)
  "Get implicit hydrogen count from HANDLE.
Works on molecules or individual atoms."
  (cl-indigo.cffi::%indigo-count-implicit-hydrogens handle))

(defun count-sssr (molecule)
  "Get SSSR (smallest set of smallest rings) count from MOLECULE handle.

Example:
  (with-molecule (mol \"c1ccccc1\")  ; Benzene
    (count-sssr mol))
  => 1"
  (cl-indigo.cffi::%indigo-count-sssr molecule))

(defun count-stereocenters (molecule)
  "Get stereocenter count from MOLECULE handle."
  (cl-indigo.cffi::%indigo-count-stereocenters molecule))

;;;; =========================================================================
;;;; Coordinate Functions
;;;; =========================================================================

(defun has-coordinates (molecule)
  "Check if MOLECULE has 2D or 3D coordinates.
Returns T if coordinates are present, NIL otherwise."
  (= 1 (cl-indigo.cffi::%indigo-has-coordinates molecule)))

(defun has-z-coord (molecule)
  "Check if MOLECULE has 3D coordinates (Z coordinate).
Returns T if 3D, NIL if 2D or no coordinates."
  (= 1 (cl-indigo.cffi::%indigo-has-z-coord molecule)))
