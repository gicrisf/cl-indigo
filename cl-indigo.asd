;;;; cl-indigo.asd - ASDF system definition for cl-indigo

(defsystem "cl-indigo"
  :version "0.1.0"
  :description "Common Lisp bindings for the Indigo cheminformatics toolkit"
  :author "Giovanni Crisalfi"
  :license "GPL-3.0"
  :homepage "https://github.com/gicrisf/cl-indigo"
  :depends-on ("cffi" "alexandria")
  :serial t
  :components
  ((:module "src"
    :components
    ((:file "packages")
     (:module "cffi"
      :components
      ((:file "library")
       (:file "types")
       (:file "bindings")
       (:file "errors")))
     (:module "core"
      :components
      ((:file "enums")
       (:file "with-macros")
       (:file "with-star-macros")))
     (:module "mol"
      :components
      ((:file "io")
       (:file "properties")
       (:file "manipulation")
       (:file "matching")
       (:file "stateless")))
     (:module "iter"
      :components
      ((:file "iterators")
       (:file "streams")))
     (:file "atom")
     (:file "bond")
     (:file "reaction")
     (:file "render"))))
  :in-order-to ((test-op (test-op "cl-indigo/test"))))

(defsystem "cl-indigo/test"
  :description "Tests for cl-indigo"
  :depends-on ("cl-indigo" "fiveam")
  :serial t
  :components
  ((:module "test"
    :components
    ((:file "packages")
     (:file "test-util")
     (:file "test-stateless")
     (:file "test-mol")
     (:file "test-iter")
     (:file "test-streams")
     (:file "test-atoms")
     (:file "test-bonds")
     (:file "test-cleanup")
     (:file "test-io")
     (:file "test-manipulation"))))
  :perform (test-op (o c)
             (symbol-call :fiveam :run! :cl-indigo-tests)))
