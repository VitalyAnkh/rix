# modules/desktop/media/daw.nix
#
# I make games on my spare time (and occasionally edit audio for videos). These
# need music and sound effects. On Windows/Mac, I used Apple Logic, Fruityloops,
# Adobe Audition, and Sunvox. To replace them on Linux, I use Ardour, LMMS,
# Audacity, and Sunvox (works everywhere), respectively.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.media.daw;
in {
  options.modules.desktop.media.daw = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.pipewire.jack.enable = true;

    user.packages = with pkgs; [
      ardour
      sunvox
      audacity

      # LMMS creates .lmmsrc.xml in $HOME on launch (see LMMS/lmms#5869).
      # Jailing it has the side-effect of rooting all file dialogs in the fake
      # home, but this is easily worked around by adding proper shortcuts.
      (mkWrapper lmms ''
        wrapProgram "$out/bin/lmms" \
          --run 'cfgdir="$XDG_CONFIG_HOME/lmms"' \
          --run 'mkdir -p "$cfgdir"' \
          --add-flags '-c "$cfgdir/rc.xml"'
      '')
    ];
  };
}
