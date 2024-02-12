{ pkgs ? import <nixpkgs> {} }:
let
  perllibs = pkgs.perl.withPackages (p: [
    p.CarpAlways
    p.DevelStackTrace
    p.HashOrdered
  ]);
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      perllibs
      gnumake
    ];
}

