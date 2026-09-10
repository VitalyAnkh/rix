# test/nixos/root.nix --- tests for ./default.nix, the root module
#
# default.nix imports all 85 modules, declares the `user` alias, and sets the
# universal defaults every host inherits. The naming breaks the mirror
# convention used elsewhere under test/nixos/ only because default.nix is taken
# here: this directory's default.nix is the check entry point.

{ evalConfig, evalSystem, system, lib, ... }:

with lib;
let
  # A host with nothing set at all, evaluated underneath the harness's
  # baseModules so that user.name really is undefined.
  bare = evalSystem {
    host = {
      inherit system;
      config = { ... }: {
        fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; };
        system.stateVersion = "23.11";
        documentation.enable = false;
      };
    };
  };
in {
  ## The `user` alias, which stands in for users.users.$USER.

  testUserIsAliasedToUsersUsers = {
    expr =
      let u = (evalConfig []).users.users.test;
      in { inherit (u) home group uid isNormalUser; };
    expected = {
      home = "/home/test";
      group = "users";
      uid = 1000;
      isNormalUser = true;
    };
  };

  # `user` borrows users.users' own element type, so lists merge instead of
  # clobbering. This used to be types.attrs, whose shallow // meant that of the
  # nine modules contributing to user.extraGroups only the last survived when
  # read back off config.user. Both views must now agree.
  testConfigUserAggregatesLists = {
    expr =
      let c = evalConfig [{
            modules.desktop.hyprland.enable = true;   # adds "input"
            modules.profiles.hardware = [ "audio" ];  # adds "audio"
          }];
      in {
        viaUser = sort lessThan c.user.extraGroups;
        viaUsersUsers = sort lessThan c.users.users.test.extraGroups;
      };
    expected = {
      viaUser = [ "audio" "input" "wheel" ];
      viaUsersUsers = [ "audio" "input" "wheel" ];
    };
  };

  # user.packages has the most contributors of any option under `user`, and is
  # the one the old shallow merge quietly truncated the worst.
  testConfigUserAggregatesPackages = {
    expr =
      let c = evalConfig [{
            modules.desktop.term.foot.enable = true;  # adds foot, libsixel
            modules.editors.vim.enable = true;
          }];
          names = map (p: p.pname or p.name) c.user.packages;
      in all (n: elem n names) [ "foot" "libsixel" ];
    expected = true;
  };

  ## The unset-name assertion, and the default that makes it detectable.

  # An unset name stays "" rather than taking the option path's own name
  # ("user"). Goes through evalSystem to get underneath baseModules, which
  # always sets one. "" is what the assertion in default.nix reads as unset,
  # and pinning it is the only reason that assertion can fail at all: it used
  # to test `config.user ? name`, which types.attrs' own { name = ""; } default
  # always satisfied.
  testUnsetUserNameIsEmpty = {
    expr = bare.user.name;
    expected = "";
  };

  # And a definition from a profile outranks that pinned default.
  testUserNameComesFromTheProfile = {
    expr = (evalConfig []).user.name;
    expected = "test";
  };

  # Not tested any further than the predicate above, deliberately. Forcing
  # config.assertions on a nameless host does not reach the assertion: the
  # list drags in systemd.services, which drags in
  # home-manager.users."".home.username, whose type rejects "" first. So the
  # friendly message is unreachable in practice and a host that forgets to set
  # a user still gets home-manager's type error instead.
  #
  # TODO testUnsetUserNameFailsItsAssertion, once that ordering is fixed

  # Nested options merge too, which types.attrs could not do at any depth.
  testConfigUserMergesNestedLists = {
    expr =
      (evalConfig [
        { user.openssh.authorizedKeys.keys = [ "key-a" ]; }
        { user.openssh.authorizedKeys.keys = [ "key-b" ]; }
      ]).user.openssh.authorizedKeys.keys;
    expected = [ "key-a" "key-b" ];
  };

  ## Universal defaults.

  testUnfreeIsAllowedInTheSessionEnvironment = {
    expr = (evalConfig []).environment.sessionVariables.NIXPKGS_ALLOW_UNFREE;
    expected = "1";
  };

  testDotfilesHomeIsExported = {
    expr = (evalConfig []).environment.sessionVariables ? DOTFILES_HOME;
    expected = true;
  };

  # A default root device is set here purely so `nix flake check` can evaluate
  # a host that has no hardware-configuration.nix of its own.
  testRootDeviceHasADefault = {
    expr =
      (evalConfig [{ fileSystems."/".device = mkForce "/dev/disk/by-label/nixos"; }])
        .fileSystems."/".device;
    expected = "/dev/disk/by-label/nixos";
  };

  testNixFlakesAreEnabled = {
    expr = hasInfix "experimental-features = nix-command flakes"
             (evalConfig []).nix.extraOptions;
    expected = true;
  };

  # The registry and nixPath are seeded from this flake's own inputs, so that
  # `nix shell nixpkgs#x` on a host resolves to the same nixpkgs the host was
  # built from.
  testNixRegistryIsSeededFromInputs = {
    expr = (evalConfig []).nix.registry ? nixpkgs;
    expected = true;
  };

  testStateVersion = {
    expr = (evalConfig []).system.stateVersion;
    expected = "23.11";
  };

  # TODO testUserNameAssertionFiresWhenUnset
}
