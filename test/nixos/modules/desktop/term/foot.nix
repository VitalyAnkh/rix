# test/nixos/modules/desktop/term/foot.nix --- tests for modules/desktop/term/
#
# Covered as the representative `mkIf cfg.enable` module: an enable flag, a
# generated config file, and a mkForce reaching into another module's options.
# If the conventions in modules/ ever shift, this is the suite that notices.

{ evalConfig, lib, ... }:

with lib;
let
  foot = (evalConfig [{ modules.desktop.term.foot.enable = true; }]);
in {
  ## The enable flag gates everything, which is the convention all 85 modules
  ## follow.

  testDisabledByDefault = {
    expr = (evalConfig []).modules.desktop.term.foot.enable;
    expected = false;
  };

  testDisabledDeploysNoConfig = {
    expr = (evalConfig []).home.configFile ? "foot/foot.ini";
    expected = false;
  };

  testEnabledDeploysConfig = {
    expr = foot.home.configFile ? "foot/foot.ini";
    expected = true;
  };

  ## term.default is a separate option from term.foot.enable: one picks the
  ## terminal, the other installs it. Enabling foot does not make it the
  ## default, which is why hosts set both.

  testTerminalDefaultsToXterm = {
    expr = (evalConfig []).environment.sessionVariables.TERMINAL;
    expected = "xterm";
  };

  testEnablingFootDoesNotMakeItDefault = {
    expr = foot.environment.sessionVariables.TERMINAL;
    expected = "xterm";
  };

  testTerminalFollowsTermDefault = {
    expr = (evalConfig [{ modules.desktop.term.default = "foot"; }])
             .environment.sessionVariables.TERMINAL;
    expected = "foot";
  };

  # xterm's desktopManager is wired to term.default with mkDefault, so picking
  # any other terminal turns it off.
  testXtermDesktopManagerFollowsTermDefault = {
    expr = map
      (t: (evalConfig [{ modules.desktop.term.default = t; }])
             .services.xserver.desktopManager.xterm.enable)
      [ "xterm" "foot" ];
    expected = [ true false ];
  };

  ## The cross-module mkForce, which is the interesting part: foot overrides
  ## tmux's terminal rather than merely defaulting it.

  testFootForcesTmuxTerm = {
    expr = foot.modules.shell.tmux.term;
    expected = "foot";
  };

  # mkForce means even an explicit definition elsewhere loses. Pinned because
  # the alternative (mkDefault) would look identical in every test that does
  # not try to override it.
  testFootTmuxTermBeatsAnExplicitDefinition = {
    expr = (evalConfig [{
      modules.desktop.term.foot.enable = true;
      modules.shell.tmux.term = "screen-256color";
    }]).modules.shell.tmux.term;
    expected = "foot";
  };

  # foot's terminfo is missing on most remotes, so ssh downgrades TERM.
  testFootDowngradesTermOverSsh = {
    expr = hasInfix "SetEnv TERM=xterm-256color" foot.programs.ssh.extraConfig;
    expected = true;
  };
}
