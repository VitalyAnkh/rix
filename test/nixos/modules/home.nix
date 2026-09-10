# test/nixos/modules/home.nix --- tests for modules/home.nix
#
# modules/home.nix exists to hide home-manager behind four aliases, so that no
# module outside it ever writes home-manager.users.<name>.*. The aliases are
# mkAliasDefinitions plumbing, which fails silently and invisibly when a rename
# upstream breaks it: files simply stop being deployed. These tests assert each
# alias still lands where it claims to.

{ evalConfig, ... }:

let
  # The alias targets all hang off the user's home-manager config.
  hm = modules: (evalConfig modules).home-manager.users.test;
in {
  testConfigFileAliasesToXdgConfigFile = {
    expr = (hm [{ home.configFile."probe/x".text = "probe"; }]).xdg.configFile."probe/x".text;
    expected = "probe";
  };

  testDataFileAliasesToXdgDataFile = {
    expr = (hm [{ home.dataFile."probe/x".text = "probe"; }]).xdg.dataFile."probe/x".text;
    expected = "probe";
  };

  testFileAliasesToHomeFile = {
    expr = (hm [{ home.file."probe/x".text = "probe"; }]).home.file."probe/x".text;
    expected = "probe";
  };

  # fakeFile is the odd one out: it is not an alias but a rewrite, prefixing
  # every path with home.fakeDir. It is the jail for programs that ignore XDG,
  # so the prefix is the entire point of the option.
  testFakeFileIsRewrittenIntoFakeDir = {
    expr =
      let c = evalConfig [{ home.fakeFile."probe/x".text = "probe"; }];
      in (c.home-manager.users.test.home.file
            ."${c.home.fakeDir}/probe/x").text;
    expected = "probe";
  };

  ## The XDG directory options, which everything above is layered on.

  testXdgDirsDeriveFromUserHome = {
    expr =
      let c = evalConfig [];
      in {
        inherit (c.home) dir binDir cacheDir configDir dataDir stateDir fakeDir;
      };
    expected = {
      dir       = "/home/test";
      binDir    = "/home/test/.local/bin";
      cacheDir  = "/home/test/.cache";
      configDir = "/home/test/.config";
      dataDir   = "/home/test/.local/share";
      stateDir  = "/home/test/.local/state";
      fakeDir   = "/home/test/.local/user";
    };
  };

  # home-manager's own xdg homes are mkForce'd to the values above, so that
  # nothing downstream can disagree about where $XDG_CONFIG_HOME points.
  testHomeManagerXdgHomesAreForced = {
    expr =
      let x = (hm []).xdg;
      in { inherit (x) cacheHome configHome dataHome stateHome; };
    expected = {
      cacheHome  = "/home/test/.cache";
      configHome = "/home/test/.config";
      dataHome   = "/home/test/.local/share";
      stateHome  = "/home/test/.local/state";
    };
  };

  testSessionVariablesExportXdgDirs = {
    expr =
      let v = (evalConfig []).environment.sessionVariables;
      in {
        inherit (v) XDG_BIN_HOME XDG_CONFIG_HOME XDG_FAKE_HOME;
      };
    expected = {
      XDG_BIN_HOME    = "/home/test/.local/bin";
      XDG_CONFIG_HOME = "/home/test/.config";
      XDG_FAKE_HOME   = "/home/test/.local/user";
    };
  };

  # home-manager needs a stateVersion of its own or it looks for a nixpkgs
  # channel, so modules/home.nix copies the system's across.
  testHomeManagerInheritsStateVersion = {
    expr = (hm []).home.stateVersion;
    expected = "23.11";
  };
}
