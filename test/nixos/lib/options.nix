# test/nixos/lib/options.nix --- tests for lib/options.nix
#
# Every one of the 85 modules declares its options through these three
# wrappers, so a change to what they emit changes every module at once.

{ lib, heyLib, ... }:

with lib;
let
  inherit (heyLib) mkOpt mkOpt' mkBoolOpt;
in {
  testMkOptTypeAndDefault = {
    expr = let o = mkOpt types.str "hi"; in { inherit (o) default; type = o.type.name; };
    expected = { default = "hi"; type = "str"; };
  };

  # mkOpt deliberately declares no description, which is why `nix flake check`
  # does not complain about undocumented options in this flake.
  testMkOptHasNoDescription = {
    expr = (mkOpt types.str "hi") ? description;
    expected = false;
  };

  testMkOptPrimeAddsDescription = {
    expr = (mkOpt' types.str "hi" "a greeting").description;
    expected = "a greeting";
  };

  testMkBoolOpt = {
    expr =
      let o = mkBoolOpt false;
      in { inherit (o) default example; type = o.type.name; };
    expected = { default = false; example = true; type = "bool"; };
  };
}
