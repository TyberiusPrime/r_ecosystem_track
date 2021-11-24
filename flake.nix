{
  description = "version a ware R wrapper";

  inputs = rec {
    nixpkgs.url =
      "github:nixOS/nixpkgs?rev=cd63096d6d887d689543a0b97743d28995bc9bc3";
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
                version = "4.1.0";
                major_version = builtins.substring 0 1 version;
                name = pname + "-" + version;

                src = pkgs.fetchurl {
                  url =
                    "http://cran.r-project.org/src/base/R-${major_version}/${name}.tar.gz";
                  sha256 =
                    "e8e68959d7282ca147360fc9644ada9bd161bab781bab14d33b8999a95182781";
                };
                patches = [
                  ./r_patches/no-usr-local-search-paths.patch
                  ./r_patches/7543c28b931db386bb254e58995973493f88e30d.patch
                  ./r_patches/7715c67cabe13bb15350cba1a78591bbb76c7bac.patch
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
        rWrapper = rWrapper;
        rPackages = rPackages;
        defaultPackage = rWrapper.override {
          packages = with rPackages; [ dplyr ] ++ rWrapper.recommendedPackages;
        };
      });
}
