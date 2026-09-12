# test/nixos/lib/modules.nix --- tests for lib/modules.nix
#
# These are the walkers the whole flake is built on: default.nix loads all of
# modules/ through mapModulesRec', flake.nix builds hosts through mapHosts, and
# lib/default.nix loads itself through mapModules. Their skip rules are
# load-bearing and entirely undocumented outside the code, so they are pinned
# here against the fixture tree in modules.d/ (see its README).

{ lib, heyLib, ... }:

with lib;
let
  inherit (heyLib)
    mapModules mapModules' mapModulesRec mapModulesRec' modulePaths mapHosts;
  fixtures = ./modules.d;
in {
  # FOO.nix and FOO/ both want the attribute name FOO, and listToAttrs keeps
  # whichever it sees first, so one of them is silently dropped. The file wins:
  # concatMapAttrs reverses its entries before listToAttrs, which puts the later
  # readDir name first. This flipped when the walkers moved off mapAttrs' (the
  # directory used to win), so it is pinned rather than left to drift. Nothing in
  # the repo has such a collision; if that changes, this is where to look.
  testMapModulesNameCollisionPrefersTheFile = {
    expr = mapModules ./collision.d import;
    expected = { dup = "from-file"; };
  };

  # A .nix file is taken by its basename; a directory only if it holds a
  # default.nix. default.nix itself, '_'-prefixed names and non-.nix files are
  # all skipped.
  testMapModulesSkipRules = {
    expr = mapModules fixtures import;
    expected = { alpha = "alpha"; beta = "beta"; };
  };

  testMapModulesPrimeIsValues = {
    expr = mapModules' fixtures import;
    expected = [ "alpha" "beta" ];
  };

  # mapModulesRec descends into every directory, including ones mapModules
  # skipped for lacking a default.nix (gamma). Only the '_' prefix stops it.
  testMapModulesRecDescendsEverywhere = {
    expr = mapModulesRec fixtures import;
    expected = {
      alpha = "alpha";
      # beta holds nothing but a default.nix, and default.nix is skipped, so
      # recursing into it yields an empty set rather than "beta".
      beta = {};
      gamma.inner = "gamma/inner";
    };
  };

  # mapModulesRec' flattens the tree instead of nesting it, and takes a
  # default.nix-bearing directory as the directory itself (beta), which import
  # resolves back to that file.
  testMapModulesRecPrimeFlattensTheTree = {
    expr = mapModulesRec' fixtures baseNameOf;
    expected = [ "alpha.nix" "beta" "inner.nix" ];
  };

  # Every path comes back rooted in the tree it was read out of. This is the
  # regression guard for interpolating DIR as a path instead of stringifying it:
  # doing so copies the tree into the store, and every path below the top level
  # then points into that copy rather than at the real source.
  testMapModulesRecPrimeDoesNotCopyToTheStore = {
    expr = all (hasPrefix "${toString fixtures}/") (modulePaths fixtures);
    expected = true;
  };

  testMapHostsNames = {
    expr = attrNames (mapHosts fixtures);
    expected = [ "alpha" "beta" ];
  };

  testMapHostsShape = {
    expr = (mapHosts fixtures).alpha.config;
    expected = "alpha";
  };
}
