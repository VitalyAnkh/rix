{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.browsers;
in {
  options.modules.apps.browsers = {
    default = mkOpt (with types; nullOr str) null;
  };

  config = mkIf (cfg.default != null) {
    environment.sessionVariables.BROWSER = cfg.default;
  };
}
