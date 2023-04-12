# modules/desktop/media/video.nix --- the pictures. They move.
#
# For all things video. Video playback, (en|de)coding, and editing.  OBS to
# capture footage/stream, audacity for audio, handbrake/ffmpeg to encode it all.
# This, paired with DaVinci Resolve for video editing and I'm set for the
# occasional gameplay, instructional, or product demo video.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.media.video;
in {
  options.modules.desktop.media.video = {
    enable = mkBoolOpt false;
    capture.enable = mkBoolOpt false;
    editor.enable = mkBoolOpt false;
    player.enable = mkBoolOpt true;
    tools.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.capture.enable {
      user.packages = [
        pkgs.obs-studio  # For recording footage
      ];
    })

    (mkIf cfg.editor.enable {
      user.packages = [
        pkgs.davinci-resolve  # For editing it
      ];
    })

    (mkIf cfg.player.enable {
      user.packages = with pkgs; [
        mpv
        mpvc  # CLI controller for mpv
      ];

      # Use hardware decoding, if available
      home.configFile."mpv/mpv.conf".text = ''
        hwdec=auto
      '';
    })

    (mkIf cfg.tools.enable {
      user.packages = with pkgs; [
        # For (en|de)coding
        ffmpeg     # ...in the CLI
        handbrake  # ...for the GUI
      ];
    })
  ]);
}
