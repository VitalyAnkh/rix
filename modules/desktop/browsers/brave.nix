# modules/browser/brave.nix --- https://publishers.basicattentiontoken.org
#
# A FOSS and privacy-minded browser.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.browsers.brave;
in {
  options.modules.desktop.browsers.brave = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      brave
      (mkLauncherEntry "Brave Web Browser" {
        description = "Open a private Brave window";
        icon = "brave";
        exec = "${brave}/bin/brave --incognito";
        categories = [ "Network" ];
      })
    ];
  };
}
