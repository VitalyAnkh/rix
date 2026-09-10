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
  inherit (heyLib) mapModules mapModules' mapModulesRec mapModulesRec' mapHosts;
  fixtures = ./modules.d;
in {
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
  # skipped for lacking a default.nix (gamma) and ones carrying a .noload
  # marker (noload). Only the '_' prefix stops it.
  testMapModulesRecDescendsEverywhere = {
    expr = mapModulesRec fixtures import;
    expected = {
      alpha = "alpha";
      # beta holds nothing but a default.nix, and default.nix is skipped, so
      # recursing into it yields an empty set rather than "beta".
      beta = {};
      gamma.inner = "gamma/inner";
      noload.skipped = "noload/skipped";
    };
  };

  # mapModulesRec' is the only walker that honours .noload, which is why
  # modules/ can park a subtree without deleting it.
  testMapModulesRecPrimeHonoursNoload = {
    expr = mapModulesRec' fixtures baseNameOf;
    expected = [ "alpha.nix" "beta" "inner.nix" ];
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
