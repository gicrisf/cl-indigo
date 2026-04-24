;;; render-mol.lisp - Standalone script to render a molecule to SVG
;;;
;;; Usage:
;;;   sbcl --script render-mol.lisp [SMILES [output-file]]
;;;
;;; Default: renders ethanol (CCO) to /tmp/mol.svg

(load "~/quicklisp/setup.lisp")
(push #p"./" asdf:*central-registry*)
(asdf:load-system :cl-indigo)

(use-package :cl-indigo)

(defun render-mol (smiles output-path)
  (with-molecule (mol smiles)
    (layout mol)
    (set-option "render-output-format" "svg")
    (set-option-int "render-image-width" 400)
    (set-option-int "render-image-height" 300)
    (set-option-float "render-bond-length" 40.0)
    (render-to-file mol output-path))
  (format t "SVG saved to ~A~%" output-path))

(let* ((args (cdr sb-ext:*posix-argv*))
       (smiles (or (first args) "CCO"))
       (output (or (second args) "/tmp/mol.svg")))
  (render-mol smiles output))
