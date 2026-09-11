# modules/apps/ue.nix --- https://unrealengine.com
#
# ...

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.ue;
in {
  options.modules.apps.ue = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      ue4
    ];
  };
}
