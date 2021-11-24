# R_ecosystem_track

Per day versioned R ecosystems.

This leverages [nix flakes](https://nixos.wiki/wiki/Flakes) to make R reproducible.

For every day that Bioconductor 'changed', there's (eventually) a branch in this repo, with a
nix flake that allows you to install 'all' R packages and their ecosystem as you
would have been able to at this date.

All here means CRAN + Bioconductor (software, annotation, experiments).

'Changed' means either a Bioconductor release date, an R (minor) release date,
or a date on which any Bioconductor 'software' package was replaced (only for
Bioconductor releases >= 3.6, before that no 'Archive' was available.).

This goes back to Bioconductor 3.0 - after that, no daily CRAN snapshot mirror was 
available (and the nixpkgs ecosystem also starts to be usable around that time).

See https://github.com/TyberiusPrime/cran_tracker_for_nix
for how this is being generated & additional details.

Each commit has had all it's packages successfully build, or marked broken, often
with a helpful note as to when it starts working again. For example, Bioconductor 3.14
as of it's release date is missing only 28 packages.

There's a json files excluded & broken packages in each commit. The difference
is that broken packages can't build (but are defined in the nix derivations),
while excluded packages (which do not have nix derivations) had no source
available at that date or were present in different versions between
bioconductor and CRAN (higher version then wins).

## Quick links to preferred versions

 * [Bioconductor 3.14](https://github.com/TyberiusPrime/r_ecosystem_track/releases/tag/2021-10-28_1) (day after release -3.14 replaced a lot of packages straight away), hash e39d7014b32f43fe82785a8e9701cfd0ece9854d
 * [Bioconductor 3.13](https://github.com/TyberiusPrime/r_ecosystem_track/releases/tag/2021-05-20_1) (release date) hash cf6559a7b006e8efe0d618aa4bdd13be002be78e
 * Bioconductor 3.13 (last 3.13 date, (tbd))

## Why are there multiple commits on a branch, each tagged with a numeric suffix

The goal here is to enable reproducibility, but not all packages are currently building .

If I need to apply any bug fixes, or am able to extend the set of buildable packages 
(PRs are welcome), the numeric suffix will be bumped, so downstreams can still use the old
definitions, and it's easy to reference in academic papers.

## What's the update frequency on this?

Not sure yet, I'll strive to update it most days, but no promises. CI is problematic because
any given update could mean rebuilding thousands of R Packages for testing,
which takes hours even on 48 cores.


## This must have been a lot of work

You have no idea.

And it's not done yet, the why-does-this-not-build-archeology continues!


## How to use

### Option A) straight flake

Here's an example flake:
```nix
{
  description = "R_ecosystem  example flake";
  inputs = rec {

    r_ecosystem_track = {
      url =
        "github:TyberiusPrime/r_ecosystem_track?rev=e39d7014b32f43fe82785a8e9701cfd0ece9854d"; # that's 2011-10-28_1 which is bioconductor 3.14

    };
  };

  outputs = { self, r_ecosystem_track }: {
    defaultPackage.x86_64-linux = with r_ecosystem_track;
      rWrapper.x86_64-linux.override {
        packages = with rPackages.x86_64-linux; [ ggplot2 ];
      };
  };
}
```


### Using anysnake2

If you're using [anysnake2](https://github.com/TyberiusPrime/anysnake2) (>= 0.9) (which is a fancy wrapper around nix flakes and singularity), 
all you need to do is add the following to your anysnake2.toml:

```toml
[R]
ecosystem_tag="2021-10-28_1" # a tag from this repo
packages = [
  "ggplot2",
  "dplyr"
]
```


