# test/nixos/modules/matugen.nix --- tests for modules/hyprland/matugen.nix
#
# This module hand-assembles TOML, and matugen parses it with no
# deny_unknown_fields, so a malformed or misspelled key is silently ignored
# rather than failing the build. These tests read the generated config.toml back
# and assert on what came out.

{ evalConfig, lib, ... }:

with lib;
let
  matugen = modules:
    (evalConfig modules).home.configFile."matugen/config.toml".text;

  # The module writes nothing until something registers, so the baseline every
  # "is it absent?" test reads is a config with one unrelated template in it.
  bare = matugen [{
    modules.hyprland.matugen.templates.example.input_path = "/in";
  }];
in {
  ## The config table.

  testConfigTableIsPresent = {
    expr = hasInfix "[config]" bare;
    expected = true;
  };

  # matugen resolves import_json_files relative to the config file, and drops
  # them silently if the path is wrong, so this stays pinned to an absolute one.
  testInfoJsonIsImported = {
    expr = hasInfix ''import_json_files = ["/home/test/.local/share/hey/info.json"]'' bare;
    expected = true;
  };

  # ConfigFile.templates is not Option<_> in matugen, so a config carrying only
  # colors still has to emit the header or the run dies with
  # "missing field `templates`".
  testTemplatesTableSurvivesWithNoTemplates = {
    expr = hasInfix "\n[templates]\n" (matugen [{
      modules.hyprland.matugen.colors.brand = "#ff0000";
    }]);
    expected = true;
  };

  # The module has no enable option (see modules/hyprland/matugen.nix), so this
  # is what keeps it from writing a config.toml on hosts that never asked.
  testNothingIsWrittenUntilSomethingRegisters = {
    expr = (evalConfig []).home.configFile ? "matugen/config.toml";
    expected = false;
  };

  ## Custom colors.

  # Emitted as sub-tables rather than inline pairs: TOML can't reopen a parent
  # table once a sub-table starts, so the inline form would be order-sensitive.
  testBareHexColorIsNormalised = {
    expr = hasInfix ''
      [config.custom_colors.brand]
      color = "#ff0000"
      blend = true
    '' (matugen [{ modules.hyprland.matugen.colors.brand = "#ff0000"; }]);
    expected = true;
  };

  testColorSubmoduleKeepsBlend = {
    expr = hasInfix ''
      [config.custom_colors.accent]
      color = "#00ff00"
      blend = false
    '' (matugen [{
      modules.hyprland.matugen.colors.accent = { color = "#00ff00"; blend = false; };
    }]);
    expected = true;
  };

  testNoColorsMeansNoCustomColorsTable = {
    expr = hasInfix "custom_colors" bare;
    expected = false;
  };

  ## Templates.

  testTemplateRendersInputAndOutput = {
    expr = hasInfix ''
      [templates.example]
      input_path = "/in"
      output_path = "/out"
    '' (matugen [{
      modules.hyprland.matugen.templates.example = {
        input_path = "/in";
        output_path = "/out";
      };
    }]);
    expected = true;
  };

  # An empty output_path would make matugen write to the config dir; an empty
  # hook would run a no-op shell. Both keys have to disappear when unset.
  testUnsetKeysAreOmitted = {
    expr =
      let text = matugen [{
            modules.hyprland.matugen.templates.example.input_path = "/in";
          }];
      in [ (hasInfix "output_path" text)
           (hasInfix "pre_hook" text)
           (hasInfix "post_hook" text) ];
    expected = [ false false false ];
  };

  testHooksAreEmittedWhenSet = {
    expr = hasInfix ''pre_hook = "touch /tmp/a"'' (matugen [{
      modules.hyprland.matugen.templates.example = {
        input_path = "/in";
        pre_hook = "touch /tmp/a";
      };
    }]);
    expected = true;
  };

  # Hooks are shell, so they will eventually contain quotes. TOML basic strings
  # need those escaped, which is why the module emits every value via toJSON.
  testStringsAreEscaped = {
    expr = hasInfix ''post_hook = "echo \"hi\""'' (matugen [{
      modules.hyprland.matugen.templates.example = {
        input_path = "/in";
        post_hook = ''echo "hi"'';
      };
    }]);
    expected = true;
  };

  ## Registration by the application modules.
  ##
  ## Each module owns its own template now, so the test that matters is that
  ## enabling the application is what puts it in the file.

  testTmuxRegistersItsTemplate = {
    expr = hasInfix "[templates.tmux]" (matugen [{ modules.shell.tmux.enable = true; }]);
    expected = true;
  };

  testDisabledTmuxRegistersNothing = {
    expr = hasInfix "[templates.tmux]" bare;
    expected = false;
  };

  testRofiRegistersItsTemplate = {
    expr = hasInfix "[templates.rofi]" (matugen [{
      modules.apps.rofi.enable = true;
    }]);
    expected = true;
  };

  testFootRegistersItsTemplate = {
    expr = hasInfix ''output_path = "/home/test/.config/foot/dank-colors.ini"'' (matugen [{
      modules.apps.term.foot.enable = true;
    }]);
    expected = true;
  };

  # ghostty/config has sourced ?config.theme since it was written, but the
  # template was never registered, so the file was never generated.
  testGhosttyRegistersItsTemplate = {
    expr = hasInfix ''output_path = "/home/test/.config/ghostty/config.theme"'' (matugen [{
      modules.apps.term.ghostty.enable = true;
    }]);
    expected = true;
  };

  ## LibreWolf, which is the only module contributing more than one template.

  testLibrewolfCoversBothProfiles = {
    expr =
      let text = matugen [{ modules.apps.browsers.librewolf.enable = true; }];
      in map (name: hasInfix "[templates.${name}]" text) [
        "librewolf-chrome-default" "librewolf-content-default"
        "librewolf-chrome-alt"     "librewolf-content-alt"
      ];
    expected = [ true true true true ];
  };

  # hyprland.nix used to hardcode this profile directory, and drifted from
  # librewolf's own profileName option as a result.
  testLibrewolfFollowsProfileName = {
    expr = hasInfix "/librewolf/librewolf/bob.default/chrome/userChrome.colors.css" (matugen [{
      modules.apps.browsers.librewolf.enable = true;
      modules.apps.browsers.librewolf.profileName = "bob";
    }]);
    expected = true;
  };
}
