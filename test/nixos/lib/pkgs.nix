# test/nixos/lib/pkgs.nix --- tests for lib/pkgs.nix
#
# Only the pure helpers are covered. mkWrapper, mkLauncherEntry and compileSCSS
# all build derivations, and compileSCSS additionally calls readFile on one, so
# they belong in a suite that is willing to pay for a build.
#
# TODO testMkLauncherEntry
# TODO testToPrettyJSON

{ lib, heyLib, ... }:

with lib;
let
  inherit (heyLib) boolTo boolToStr;
in {
  testBoolToTrue = {
    expr = boolTo true "yes" "no";
    expected = "yes";
  };

  # boolTo's falsey set is false, null and 0 -- deliberately not Nix's, which
  # has no notion of truthiness at all. Anything else, including the empty
  # string and the empty list, takes the true branch.
  testBoolToFalseySet = {
    expr = map (v: boolTo v "yes" "no") [ false null 0 ];
    expected = [ "no" "no" "no" ];
  };

  testBoolToEmptyStringIsTruthy = {
    expr = boolTo "" "yes" "no";
    expected = "yes";
  };

  testBoolToEmptyListIsTruthy = {
    expr = boolTo [] "yes" "no";
    expected = "yes";
  };

  testBoolToStr = {
    expr = [ (boolToStr true) (boolToStr false) ];
    expected = [ "true" "false" ];
  };
}
