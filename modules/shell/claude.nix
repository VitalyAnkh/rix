# modules/shell/claude.nix
#
# AI has become so ubiquitious that I can't avoid installing it just to support
# clients who (ab)use it.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.claude;
in {
  options.modules.shell.claude = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      claude-code
    ];

    # Respect XDG, damn it!
    environment.sessionVariables = {
      CLAUDE_CONFIG_DIR = "${config.home.dataDir}/claude";
    };
  };
}
