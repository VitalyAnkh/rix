# test/nixos/modules/desktop/hyprland.nix --- tests for modules/desktop/hyprland.nix
#
# This module generates config/hypr/hyprland.lua from cfg.monitors, so a change
# to the option schema or the template silently produces a Hyprland config that
# is wrong rather than one that fails to build. These tests read the generated
# Lua back and assert on what came out.
#
# TODO testExtraConfigLandsInHyprlandPostLua
# TODO testMatugenTemplatesFollowTerminalChoice

{ evalConfig, lib, ... }:

with lib;
let
  hyprland = monitors: evalConfig [{
    modules.desktop.hyprland.enable = true;
    modules.desktop.hyprland.monitors = monitors;
  }];

  lua = monitors: (hyprland monitors).home.configFile."hypr/hyprland.lua".text;

  countMonitors = text: (length (splitString "hl.monitor({" text)) - 1;
in {
  ## Enabling the module.

  # hyprland.nix turns on the desktop profile for you, which is what pulls in
  # everything under modules/desktop/.
  testEnableImpliesDesktop = {
    expr = (hyprland [{}]).modules.desktop.enable;
    expected = true;
  };

  testDisabledByDefault = {
    expr = (evalConfig []).modules.desktop.enable;
    expected = false;
  };

  # Needed by the DMS screenkey plugin, and easy to lose in a refactor because
  # nothing else in the module mentions it.
  testEnableAddsUserToInputGroup = {
    expr = elem "input" (hyprland [{}]).user.extraGroups;
    expected = true;
  };

  ## Monitor emission.

  testOneMonitorCallPerMonitor = {
    expr = countMonitors (lua [
      { output = "DP-1"; }
      { output = "DP-2"; }
      { output = "DP-3"; }
    ]);
    expected = 3;
  };

  # The submodule's defaults end up verbatim in the Lua, so they are part of
  # this module's contract with config/hypr/, not just with Nix.
  testMonitorDefaultsAreEmitted = {
    expr = hasInfix ''
      hl.monitor({
        output = "DP-1",
        mode = "preferred",
        position = "auto",
        scale = 1,
        disabled = false,
        vrr = 0
      })
    '' (lua [{ output = "DP-1"; }]);
    expected = true;
  };

  testMonitorOverridesAreEmitted = {
    expr = hasInfix ''
      hl.monitor({
        output = "DP-2",
        mode = "3840x2160@120",
        position = "0x0",
        scale = 2,
        disabled = true,
        vrr = 1
      })
    '' (lua [{
      output = "DP-2";
      mode = "3840x2160@120";
      position = "0x0";
      scale = 2;
      disabled = true;
      vrr = 1;
    }]);
    expected = true;
  };

  testHostnameIsEmitted = {
    expr = hasInfix ''HOSTNAME = "test"'' (lua [{ output = "DP-1"; }]);
    expected = true;
  };

  ## The primary monitor, which Wayland has no notion of and which the module
  ## fakes with an xrandr call on session start.

  testPrimaryMonitorIsPickedFromTheList = {
    expr = hasInfix ''PRIMARY_MONITOR = "DP-2"'' (lua [
      { output = "DP-1"; }
      { output = "DP-2"; primary = true; }
    ]);
    expected = true;
  };

  # findFirst returns {} when no monitor is primary, and the whole block is
  # guarded on `primaryMonitor ? output`, so nothing is emitted at all. This is
  # the default case: monitors defaults to [{}], none of them primary.
  testNoPrimaryMonitorEmitsNothing = {
    expr = hasInfix "PRIMARY_MONITOR" (lua [{ output = "DP-1"; }]);
    expected = false;
  };

  testFirstPrimaryWins = {
    expr = hasInfix ''PRIMARY_MONITOR = "DP-1"'' (lua [
      { output = "DP-1"; primary = true; }
      { output = "DP-2"; primary = true; }
    ]);
    expected = true;
  };

  ## The matugen colour fallback.

  # This one reads backwards on purpose, and is pinned so that correcting it has
  # to be a deliberate act. The generated Lua opens hyprland-colors.lua and
  # requires it only in the branch where the file could NOT be opened:
  #
  #   local f = io.open(".../hyprland-colors.lua")
  #   if f ~= nil then io.close(f) else require("hyprland-colors") end
  #
  # If that is ever inverted, the require moves out of the else branch and this
  # test fails.
  testColorsRequireSitsInTheElseBranch = {
    expr =
      let tail = last (splitString "local f = io.open" (lua [{ output = "DP-1"; }]));
          afterElse = last (splitString "else" tail);
      in hasInfix ''require("hyprland-colors")'' afterElse;
    expected = true;
  };
}
