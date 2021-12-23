# This file defines the composition for CRAN (R) packages.

{ R, pkgs, overrides, breakpointHook, importCargo, system }:

let
  inherit (pkgs) fetchurl stdenv lib;
  flock = if builtins.hasAttr "flock" pkgs then
    pkgs.flock
  else
    with pkgs;
    stdenv.mkDerivation rec {
      pname = "flock";
      name = "${pname}-${version}";
      version = "0.2.3";

      src = fetchFromGitHub {
        owner = "discoteq";
        repo = pname;
        rev = "v${version}";
        sha256 = "1vdq22zhdfi7wwndsd6s7fwmz02fsn0x04d7asq4hslk7bjxjjzn";
      };
      patches = [ ./patches/flock_no_man.patch ]; # don't want to pull in ruby and gem and stuff for the man page here.

      nativeBuildInputs = [ autoreconfHook ];
      buildInputs = [ ];

      meta = with lib; {
        description = "Cross-platform version of flock(1)";
        maintainers = [ maintainers.matthewbauer ];
        platforms = platforms.all;
        license = licenses.isc;
      };
    };

  buildRPackage = pkgs.callPackage ./generic-builder.nix {
    inherit R;
    inherit flock;
  };

  # Generates package templates given per-repository settings
  #
  # some packages, e.g. cncaGUI, require X running while installation,
  # so that we use xvfb-run if requireX is true.
  mkDerive = { mkHomepage, mkUrls }:
    args:
    lib.makeOverridable ({ name, version, sha256, depends ? [ ], doCheck ? true
      , requireX ? false, broken ? false, hydraPlatforms ? R.meta.hydraPlatforms
      , nativeBuildInputs ? [ ], buildInputs ? [ ], patches ? [ ], url ? false
      , extra_attrs ? { }, extra_override_derivations ? null }:
      let
        rpkg = buildRPackage ({
          name = name;
          version = version;
          src = fetchurl {
            inherit sha256;
            urls = mkUrls (args // { inherit name version; });
          };
          inherit doCheck requireX;
          propagatedBuildInputs = nativeBuildInputs ++ depends;
          nativeBuildInputs = nativeBuildInputs ++ depends ++ [ R ];
          additional_buildInputs = buildInputs;
          patches = patches;
          meta.homepage = mkHomepage name;
          meta.platforms = R.meta.platforms;
          meta.hydraPlatforms = hydraPlatforms;
          meta.broken = broken;
        } // extra_attrs);
        outpkg = if extra_override_derivations == null then
          rpkg
        else
          extra_override_derivations rpkg;

      in outpkg);

  # Templates for generating Bioconductor and CRAN packages
  # from the name, version, sha256, and optional per-package arguments above
  #
  deriveBioc = mkDerive {
    mkHomepage = name:
      "http://bioconductor.org/packages/release/bioc/html/${name}.html";
    mkUrls = { name, version, biocVersion }: [

      "mirror://bioc/${biocVersion}/bioc/src/contrib/${name}_${version}.tar.gz"
      #"https://bioarchive.galaxyproject.org/${name}_${version}.tar.gz" # only has some versions. and the hashes ain't identical
      "mirror://bioc/${biocVersion}/bioc/src/contrib/Archive/${name}/${name}_${version}.tar.gz"
      "mirror://bioc/${biocVersion}/bioc/src/contrib/Archive/${name}_${version}.tar.gz"
      "http://bioconductor.org/packages/${biocVersion}/bioc/src/contrib/${name}_${version}.tar.gz"
    ];
  };
  deriveBiocAnn = mkDerive {
    mkHomepage = { name, ... }:
      "http://www.bioconductor.org/packages/${name}.html";
    mkUrls = { name, version, biocVersion }: [
      "mirror://bioc/${biocVersion}/data/annotation/src/contrib/${name}_${version}.tar.gz"
      "http://bioconductor.org/packages/${biocVersion}/data/annotation/src/contrib/${name}_${version}.tar.gz"
    ];
  };
  deriveBiocExp = mkDerive {
    mkHomepage = { name, ... }:
      "http://www.bioconductor.org/packages/${name}.html";
    mkUrls = { name, version, biocVersion }: [
      "mirror://bioc/${biocVersion}/data/experiment/src/contrib/${name}_${version}.tar.gz"
      "http://bioconductor.org/packages/${biocVersion}/data/experiment/src/contrib/${name}_${version}.tar.gz"
    ];
  };
  deriveCran = mkDerive {
    mkHomepage = name: snapshot:
      "http://mran.revolutionanalytics.com/snapshot/${snapshot}/web/packages/${name}/";
    mkUrls = { name, version, snapshot, url ? false }:
      if builtins.isString (url) then
        url
      else
        [
          "http://mran.revolutionanalytics.com/snapshot/${snapshot}/src/contrib/${name}_${version}.tar.gz"
          #can't use the cran Archive - they occasionally have different sha256 from the snapshots
          #we are using.
          #"http://cran.r-project.org/src/contrib/00Archive/${name}/${name}_${version}.tar.gz"
          #"mirror://cran/src/contrib/00Archive/${name}/${name}_${version}.tar.gz"
          #"mirror://cran/src/contrib/${name}_${version}.tar.gz"
        ];
  };

  self = _self;
  _self = import ./generated/bioc-packages.nix {
    inherit stdenv;
    inherit self;
    inherit lib;
    inherit pkgs;
    inherit breakpointHook;
    derive = deriveBioc;
  } // import ./generated/bioc-annotation-packages.nix {
    inherit stdenv;
    inherit self;
    inherit lib;
    inherit pkgs;
    inherit breakpointHook;
    derive = deriveBiocAnn;
  } // import ./generated/bioc-experiment-packages.nix {
    inherit stdenv;
    inherit self;
    inherit lib;
    inherit pkgs;
    inherit breakpointHook;
    derive = deriveBiocExp;
  } // import ./generated/cran-packages.nix {
    inherit system;
    inherit stdenv;
    inherit self;
    inherit lib;
    inherit pkgs;
    inherit breakpointHook;
    inherit importCargo;
    derive = deriveCran;
  };

  # tweaks for the individual packages and "in self" follow

in self
