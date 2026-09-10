# test/nixos/lib/attrs.nix --- tests for lib/attrs.nix
#
# mergeAttrs' gets the most attention here because lib/default.nix uses it to
# flatten every lib/*.nix namespace into one set, so its precedence rules decide
# what happens on a name collision between two lib files.

{ lib, heyLib, ... }:

with lib;
let
  inherit (heyLib)
    attrsToList mapFilterAttrs mapFilterAttrs' filterMapAttrs genAttrs'
    anyAttrs countAttrs mergeAttrs' flattenAttrs;
in {
  testAttrsToList = {
    expr = attrsToList { a = 1; b = 2; };
    expected = [ { name = "a"; value = 1; } { name = "b"; value = 2; } ];
  };

  ## mergeAttrs', branch by branch.

  # A key present in only one input passes through untouched (the `tail values
  # == []` branch).
  testMergeAttrsPassesThroughUniqueKeys = {
    expr = mergeAttrs' [ { a = 1; } { b = 2; } ];
    expected = { a = 1; b = 2; };
  };

  # Lists concatenate rather than overwrite. This is why a module can add to
  # user.extraGroups without clobbering it.
  testMergeAttrsConcatsLists = {
    expr = mergeAttrs' [ { a = [ 1 2 ]; } { a = [ 3 ]; } ];
    expected = { a = [ 1 2 3 ]; };
  };

  # Attrsets recurse, which is the whole point of the function over //.
  testMergeAttrsRecursesIntoAttrsets = {
    expr = mergeAttrs' [ { a.b = 1; a.c = 2; } { a.c = 3; a.d = 4; } ];
    expected = { a = { b = 1; c = 3; d = 4; }; };
  };

  # Everything else is last-wins. Note the docstring on mergeAttrs' claims
  # "left > right"; the implementation's fallback is `last values`, so it is
  # right-wins. The behaviour is pinned here, not the comment.
  testMergeAttrsScalarsAreRightWins = {
    expr = mergeAttrs' [ { a = 1; } { a = 2; } { a = 3; } ];
    expected = { a = 3; };
  };

  # A list meeting a non-list falls through to last-wins, because `all isList`
  # fails. Worth pinning: it is the case that silently drops data.
  testMergeAttrsMixedTypesFallThrough = {
    expr = mergeAttrs' [ { a = [ 1 ]; } { a = 2; } ];
    expected = { a = 2; };
  };

  ## The predicate helpers.

  testMapFilterAttrs = {
    expr = mapFilterAttrs (n: v: v * 2) (n: v: v > 2) { a = 1; b = 2; c = 3; };
    expected = { b = 4; c = 6; };
  };

  testMapFilterAttrsPrime = {
    expr = mapFilterAttrs' (n: v: nameValuePair "x${n}" v) (n: _: n != "xa") { a = 1; b = 2; };
    expected = { xb = 2; };
  };

  testFilterMapAttrs = {
    expr = filterMapAttrs (n: _: n != "a") (_: v: v * 10) { a = 1; b = 2; };
    expected = { b = 20; };
  };

  testGenAttrsPrime = {
    expr = genAttrs' [ 1 2 ] (n: nameValuePair "n${toString n}" n);
    expected = { n1 = 1; n2 = 2; };
  };

  testAnyAttrsTrue = {
    expr = anyAttrs (n: v: v == 2) { a = 1; b = 2; };
    expected = true;
  };

  testAnyAttrsFalse = {
    expr = anyAttrs (n: v: v == 9) { a = 1; b = 2; };
    expected = false;
  };

  testCountAttrs = {
    expr = countAttrs (n: v: v > 1) { a = 1; b = 2; c = 3; };
    expected = 2;
  };

  ## flattenAttrs, which only keeps derivations and only descends where it is
  ## explicitly invited to.

  testFlattenAttrsKeepsDerivations = {
    expr = attrNames (flattenAttrs {
      a = { type = "derivation"; };
      b = { type = "derivation"; };
    });
    expected = [ "a" "b" ];
  };

  testFlattenAttrsIgnoresNonSets = {
    expr = flattenAttrs { a = 1; b = "two"; };
    expected = {};
  };

  # A plain nested attrset is dropped, not walked. Only recurseForDerivations
  # opens a subtree.
  testFlattenAttrsNeedsRecurseForDerivations = {
    expr = attrNames (flattenAttrs {
      opaque.a = { type = "derivation"; };
      opened = {
        recurseForDerivations = true;
        a = { type = "derivation"; };
      };
    });
    expected = [ "opened/a" ];
  };
}
