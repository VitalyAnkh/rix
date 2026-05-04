{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.music;
in {
  options.modules.desktop.media.music = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      feishin        # media player
      beets          # library management
      playerctl      # to control feishen
      yt-dlp
      picard         # for editing tags
      r128gain
      shntool
      cuetools
      flac
      spek           # spectrum analysis
    ];

    home.configFile = {
      "beets" = {
        source = "${hey.configDir}/beets";
        recursive = true;
      };
    };
  };
}
