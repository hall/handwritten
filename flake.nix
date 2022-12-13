{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:davhau/mach-nix/3.5.0";
  };

  outputs = inputs@{ self, ... }:
    inputs.utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          packages =
            let
              # toga-src = pkgs.fetchFromGitHub {
              #   # owner = "beeware";
              #   owner = "hall";
              #   repo = "toga";
              #   # rev = "v0.3.0.dev39";
              #   rev = "gtk-canvas-events";
              #   sha256 = "sha256-FKafG00iLm6pqvz6ycTsSHDoQPcPjT0/pGWz0YBuDRg=";
              # };
              toga-src = builtins.fetchGit {
                url = "/home/bryton/src/github.com/beeware/toga";
              };
            in
            {
              default = with pkgs; with python310Packages; buildPythonApplication {
                pname = "handwritten";
                version = "0.0.0";
                format = "pyproject";
                src = ./.;
                nativeBuildInputs = [
                  setuptools
                ];
                propagatedBuildInputs = [
                  self.packages.${system}.toga
                  easyocr
                  numpy
                  scikitimage
                  pynput
                ];
                # strictDeps = false;
              };
              briefcase = with pkgs; with python310Packages; buildPythonApplication rec {
                pname = "briefcase";
                version = "0.3.11";
                format = "pyproject";
                doCheck = false;
                src = fetchPypi {
                  inherit pname version;
                  sha256 = "sha256-a552i/Ji+kzBHy1gmgyDJER2jBNPiVxmi/fJxqFMMe0=";
                };
                nativeBuildInputs = [
                  setuptools
                  setuptools_scm
                ];
                propagatedBuildInputs = [
                  self.packages.${system}.toga

                  # build
                  pkg-config
                  GitPython
                  cookiecutter
                  packaging
                  platformdirs
                  psutil
                  rich
                  tomli
                  docker
                  pip
                  wheel

                  # gtk
                  self.packages.${system}.toga-gtk
                  gobject-introspection
                  cairo

                  # web
                  tomli-w
                ];
                # postInstall = ''
                #   makeWrapper $out/bin/briefcase $out/bin/briefcase.wrapped \
                #     --set PIP_PREFIX '$HOME/.local' \
                #     --set PYTHONPATH '$PIP_PREFIX/${pkgs.python310.sitePackages}:$PYTHONPATH' \
                #     --set PATH '$PIP_PREFIX/bin:${pip}/bin/pip:$PATH'
                # '';
              };
              toga = with pkgs; with python310Packages; buildPythonPackage rec {
                pname = "toga";
                version = "main";
                format = "pyproject";
                src = "${toga-src}/toga";
                nativeBuildInputs = [
                  setuptools
                ];
                propagatedBuildInputs = [
                  self.packages.${system}.toga-gtk
                  self.packages.${system}.toga-core
                  self.packages.${system}.travertino
                  pycairo
                  gbulb
                ];
              };
              toga-gtk = with pkgs; with python310Packages; buildPythonPackage rec {
                pname = "toga-gtk";
                version = "0.3.0.dev39";
                src = "${toga-src}/gtk";
                doCheck = false;
                nativeBuildInputs = [
                  setuptools
                  gtk3
                  pkg-config
                  gobject-introspection
                ];
                propagatedBuildInputs = [
                  self.packages.${system}.toga-core
                  self.packages.${system}.travertino
                  gbulb
                  pycairo
                  pygobject3
                ];
              };
              toga-core = with pkgs; with python310Packages; buildPythonPackage rec {
                pname = "toga-core";
                version = "0.3.0.dev39";
                src = "${toga-src}/core";
                nativeBuildInputs = [
                  setuptools
                ];
                propagatedBuildInputs = [
                  self.packages.${system}.travertino
                  # self.packages.${system}.toga-dummy
                ];
                doCheck = false;
              };
              toga-dummy = with pkgs; with python310Packages; buildPythonPackage rec {
                pname = "toga-dummy";
                version = "0.3.0.dev39";
                src = "${toga-src}/dummy";
                nativeBuildInputs = [
                  setuptools
                ];
                # propagatedBuildInputs = [
                #   self.packages.${system}.toga-core
                # ];
              };
              travertino = with pkgs; with python310Packages; buildPythonPackage rec {
                pname = "travertino";
                version = "0.1.3";
                src = pkgs.fetchFromGitHub {
                  owner = "beeware";
                  repo = pname;
                  rev = "v${version}";
                  sha256 = "sha256-ajjV1nmGaWRKivZ9hy92JxasNI3F6JTF+NtfuY4g3L0=";
                };
                nativeBuildInputs = [
                  setuptools
                ];
              };
            };
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              appimage-run
              self.packages.${system}.default
              self.packages.${system}.briefcase
              (python310.withPackages (p: with p; [
                black
                tox
              ]))
            ];
            # shellHook = ''
            #   export PYTHONPATH=${self.packages.${system}.toga}/${pkgs.python310.sitePackages}:$PYTHONPATH
            #   export PYTHONPATH=${self.packages.${system}.toga-gtk}/${pkgs.python310.sitePackages}:$PYTHONPATH
            # '';
          };
        }
      );
}
