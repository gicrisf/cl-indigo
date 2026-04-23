{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "cl-indigo-dev";

  buildInputs = with pkgs; [
    sbcl
    rlwrap
    wget
    curl
    dpkg
    stdenv.cc.cc.lib
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$PWD/indigo-install/lib:$LD_LIBRARY_PATH"

    echo "cl-indigo dev environment"
    echo "Quick start: rlwrap sbcl"
    echo "Then load Quicklisp and the system:"
    echo "  (load \"~/quicklisp/setup.lisp\")"
    echo "  (asdf:load-system :cl-indigo)"
  '';
}
