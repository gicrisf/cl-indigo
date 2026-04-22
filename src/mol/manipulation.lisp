;;;; manipulation.lisp - Structure manipulation functions

(in-package #:cl-indigo)

;;;; =========================================================================
;;;; Aromaticity
;;;; =========================================================================

(defun aromatize (molecule)
  "Aromatize MOLECULE (detect and mark aromatic rings).
Converts Kekulé representation to aromatic representation.

Returns a keyword indicating the result:
  :changed   - Molecule was aromatized
  :unchanged - No changes needed (already aromatic or no aromatic rings)

Example:
  (with-molecule (mol \"C1=CC=CC=C1\")  ; Kekulé benzene
    (aromatize mol)
    (canonical-smiles mol))
  => \"c1ccccc1\"  ; Aromatic notation"
  (let ((result (cl-indigo.cffi::%indigo-aromatize molecule)))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "aromatize: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "aromatize: unexpected result ~A" result))))))

;;;; =========================================================================
;;;; Layout (Coordinate Generation)
;;;; =========================================================================

(defun layout (molecule)
  "Calculate 2D coordinates for MOLECULE.
Generates aesthetically pleasing 2D coordinates suitable for visualization.

Returns T on success.

Example:
  (with-molecule (mol \"CCO\")
    (layout mol)
    (has-coordinates mol))
  => T"
  ;; Note: indigoLayout returns 0 on success (POSIX convention)
  (let ((result (cl-indigo.cffi::%indigo-layout molecule)))
    (cond
      ((= result 0) t)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "layout: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "layout: unexpected result ~A" result))))))

;;;; =========================================================================
;;;; Hydrogen Handling
;;;; =========================================================================

(defun fold-hydrogens (molecule)
  "Remove explicit hydrogen atoms from MOLECULE (convert to implicit).

Returns a keyword indicating the result:
  :changed   - Hydrogens were folded
  :unchanged - No explicit hydrogens to fold

Example:
  (with-molecule (mol \"CCO\")
    (unfold-hydrogens mol)   ; Add explicit H
    (count-atoms mol)        ; => 9 (3 heavy + 6 H)
    (fold-hydrogens mol)     ; Remove explicit H
    (count-atoms mol))       ; => 3 (only heavy atoms)"
  (let ((result (cl-indigo.cffi::%indigo-fold-hydrogens molecule)))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "fold-hydrogens: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "fold-hydrogens: unexpected result ~A" result))))))

(defun unfold-hydrogens (molecule)
  "Add explicit hydrogen atoms to MOLECULE.
Makes all implicit hydrogen atoms explicit in the structure.

Returns a keyword indicating the result:
  :changed   - Hydrogens were added
  :unchanged - No implicit hydrogens to unfold

Example:
  (with-molecule (mol \"CCO\")
    (count-atoms mol)           ; => 3 (only heavy atoms)
    (unfold-hydrogens mol)      ; Add explicit H
    (count-atoms mol))          ; => 9 (3 heavy + 6 H)"
  (let ((result (cl-indigo.cffi::%indigo-unfold-hydrogens molecule)))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "unfold-hydrogens: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "unfold-hydrogens: unexpected result ~A" result))))))

;;;; =========================================================================
;;;; Normalization
;;;; =========================================================================

(defun normalize (molecule &optional options)
  "Normalize MOLECULE structure with optional OPTIONS string.

Returns a keyword indicating the result:
  :changed   - Molecule was normalized
  :unchanged - No changes needed

OPTIONS is an optional string with normalization configuration.
See Indigo documentation for available options."
  (let ((result (cl-indigo.cffi::%indigo-normalize molecule (or options ""))))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "normalize: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "normalize: unexpected result ~A" result))))))

(defun standardize (molecule)
  "Standardize MOLECULE charges, stereochemistry, etc.

Returns a keyword indicating the result:
  :changed   - Molecule was standardized
  :unchanged - No changes needed

Standardization includes:
- Charge standardization
- Stereochemistry normalization
- Other structural standardizations"
  (let ((result (cl-indigo.cffi::%indigo-standardize molecule)))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "standardize: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "standardize: unexpected result ~A" result))))))

(defun ionize (molecule ph ph-tolerance)
  "Ionize MOLECULE at specified PH with PH-TOLERANCE.

Returns a keyword indicating the result:
  :changed   - Molecule was ionized
  :unchanged - No changes needed

PH is the target pH value (typically 0.0-14.0).
PH-TOLERANCE is the acceptable pH range around the target."
  (let ((result (cl-indigo.cffi::%indigo-ionize molecule
                                                 (coerce ph 'single-float)
                                                 (coerce ph-tolerance 'single-float))))
    (cond
      ((= result 1) :changed)
      ((= result 0) :unchanged)
      ((= result -1)
       (error 'indigo-error
              :message (format nil "ionize: ~A"
                              (cl-indigo.cffi::%indigo-get-last-error))))
      (t (error 'indigo-error
                :message (format nil "ionize: unexpected result ~A" result))))))
