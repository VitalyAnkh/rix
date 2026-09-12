# modules/shell/claude.nix
#
# Oh AI, destroyer of the internet, open source, and all that is creative. Owned
# by the most morally bankrupt humans on Earth, a deleterious economic/politic
# force that does more bad than good, and when its bubble pops 2008 and 2001
# will look like vacations. Give me back affordable ram.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.claude;
in {
  options.modules.shell.claude = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      claude-code
    ];

    environment.sessionVariables = {
      # Respect XDG, damn it!
      CLAUDE_CONFIG_DIR = "${config.home.dataDir}/claude";
    };

    environment.shellAliases = {
      cl  = "claude -p";
      clb = "claude --bare -p";
    };

    systemd.user.tmpfiles.rules = [
      "d %h/.local/share/claude 700 - - - -"
    ];

    environment.etc."claude-code".source = "${hey.configDir}/claude";
  };
}
