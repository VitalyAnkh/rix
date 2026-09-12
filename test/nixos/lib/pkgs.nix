# test/nixos/lib/pkgs.nix --- tests for lib/pkgs.nix
#
# Both helpers here return derivations, so the suite asserts on the attributes
# they compute rather than on anything built. That is where the bugs live: the
# names. mkWrapper used to interpolate its package, which stringified the
# derivation to its store path and named the result after a mangled one.

{ lib, pkgs, heyLib, ... }:

with lib;
let
  inherit (heyLib) mkWrapper mkLauncherEntry;

  entry = title: exec:
    (mkLauncherEntry title { inherit exec; icon = "none"; }).name;
in {
  testMkWrapperNamesAfterThePackage = {
    expr = (mkWrapper pkgs.hello "").name;
    expected = "hello-wrapped";
  };

  # A list wraps every path but is still named after the first.
  testMkWrapperListNamesAfterTheFirst = {
    expr = (mkWrapper [ pkgs.hello pkgs.coreutils ] "").name;
    expected = "hello-wrapped";
  };

  # The entry file name hashes the title as well as the command, so these two
  # no longer land on the same file.
  testMkLauncherEntryNamesDifferByTitle = {
    expr = entry "One" "run" == entry "Two" "run";
    expected = false;
  };

  testMkLauncherEntryNamesDifferByExec = {
    expr = entry "One" "run" == entry "One" "walk";
    expected = false;
  };

  testMkLauncherEntryNameIsStable = {
    expr = entry "One" "run" == entry "One" "run";
    expected = true;
  };

  testMkLauncherEntryPrefixesTheName = {
    expr = {
      default = hasPrefix "launcher-" (entry "One" "run");
      custom = hasPrefix "menu-"
        (mkLauncherEntry "One" { exec = "run"; icon = "none"; prefix = "menu-"; }).name;
    };
    expected = { default = true; custom = true; };
  };
}
