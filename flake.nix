{
  description = "version a ware R wrapper";

  inputs = rec {
    nixpkgs.url =
      "github:nixOS/nixpkgs?rev=7e9b0dff974c89e070da1ad85713ff3c20b0ca97";
    nixpkgs.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs_master.url = # breakpointhook is not available before 19.03
      "github:nixOS/nixpkgs?rev=e55bd22bbca511c4613a33d809870792d7968d1c";
    import-cargo.url = "github:edolstra/import-cargo";
    import-cargo.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, flake-utils, nixpkgs_master, import-cargo }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (import-cargo.builders) importCargo;
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            packageOverrides = super: {
              R = super.R.overrideDerivation (old: rec {
                pname = "R";
                version = "4.1.1";
                major_version = builtins.substring 0 1 version;
                name = pname + "-" + version;

                src = pkgs.fetchurl {
                  url =
                    "http://cran.r-project.org/src/base/R-${major_version}/${name}.tar.gz";
                  sha256 =
                    "515e03265752257d0b7036f380f82e42b46ed8473f54f25c7b67ed25bbbdd364";
                };
                patches = [
                  ./r_patches/no-usr-local-search-paths.patch
                  ./r_patches/skip-check-for-aarch64.patch
                ]; # R_patches-generated
              });
            };
          };
        };
        pkgs_master = import nixpkgs_master { inherit system; };
        breakpointHook = pkgs_master.breakpointHook;

        R = pkgs.R;

        overrides = { };
        rPackages = import ./default_r.nix {
          inherit R;
          inherit pkgs;
          inherit overrides;
          inherit breakpointHook;
          inherit importCargo;
          inherit system;
        };
        lib = pkgs.lib;
        rWrapper = pkgs.callPackage ./wrapper.nix {
          recommendedPackages = with rPackages; [
            boot
            class
            cluster
            codetools
            foreign
            KernSmooth
            lattice
            MASS
            Matrix
            mgcv
            # nlme
            nnet
            rpart
            spatial
            survival
          ];
          # Override this attribute to register additional libraries.
          packages = [ ];
          nixpkgs = pkgs;
        };

      in with pkgs; {
        R = R;
        rWrapper = rWrapper;
        rPackages = rPackages;
        defaultPackage = rWrapper.override {
          packages = with rPackages; [ dplyr ] ++ rWrapper.recommendedPackages;
        };
      });
}
