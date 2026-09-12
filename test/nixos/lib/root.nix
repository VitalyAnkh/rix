# test/nixos/lib/root.nix --- tests for lib/default.nix, the library's loader

{ lib, heyLib, ... }:

with lib;
let
  fixtures = ./modules.d;
in {
  # The whole point of the flatten: a namespaced endpoint is optional.
  testNamespacedAndFlattenedAgree = {
    expr = heyLib.mapModules fixtures import;
    expected = heyLib.modules.mapModules fixtures import;
  };

  testNamespacesAreStillAddressable = {
    expr = sort lessThan (filter (n: elem n [ "modules" "nixos" "options" "pkgs" ])
                                (attrNames heyLib));
    expected = [ "modules" "nixos" "options" "pkgs" ];
  };

  # nixpkgs' lib is flattened too, which is why modules can say `with hey.lib;`
  # and still reach mkIf. Probed by behaviour, since functions never compare
  # equal in Nix.
  testNixpkgsLibIsReachable = {
    expr = heyLib.mkIf true { a = 1; };
    expected = mkIf true { a = 1; };
  };

  # Compared field by field on purpose: mkOption's result carries the type,
  # whose merge functions are lambdas, and comparing two attrsets that contain
  # lambdas is one refactor away from 'cannot compare functions'.
  testOurOwnHelpersAreReachable = {
    expr = let o = heyLib.mkOpt types.str "x";
           in { inherit (o) default; type = o.type.name; };
    expected = { default = "x"; type = "str"; };
  };

  # genAttrs' is nixpkgs', not ours, and modules/apps/media/daw.nix is its only
  # caller. Its coverage would otherwise be transitive through whichever hosts
  # happen to enable the daw module.
  testNixpkgsHelperWeDependOnIsReachable = {
    expr = heyLib.genAttrs' [ 1 2 ] (n: nameValuePair "n${toString n}" n);
    expected = { n1 = 1; n2 = 2; };
  };

  # A namespace whose name collides with one of nixpkgs' sub-libs is merged into
  # it rather than replacing it, so lib/debug.nix's inspect and nixpkgs'
  # traceSeqN both survive under the same key.
  testCollidingNamespacesMerge = {
    expr = {
      ours = heyLib.debug ? inspect;
      theirs = heyLib.debug ? traceSeqN;
    };
    expected = { ours = true; theirs = true; };
  };
}
