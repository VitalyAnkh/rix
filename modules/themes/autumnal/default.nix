# modules/themes/autumnal/default.nix --- a dark, pastel theme

{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in mkIf (cfg.active == "autumnal") (mkMerge [
  {

    modules = {
      # shell.zsh.rcFiles  = [ ./config/zsh/prompt.zsh ];
      # shell.tmux.rcFiles = [ ./config/tmux.conf ];
      # desktop.browsers = {
      #   librewolf = {
      #     settings."devtools.theme" = "dark";
      #     userChrome = concatMapStringsSep "\n" readFile [
      #       ./config/librewolf/userChrome.css
      #     ];
      #   };
      # };
    };
  }

  # (mkIf config.modules.desktop.enable {
  #   home.configFile = with config.modules; mkMerge [
  #     {
  #       "Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini {}).generate "kvantum.kvconfig" {
  #         General.theme = "Catppuccin-Mocha-Mauve";
  #       };
  #     }
  #     (mkIf desktop.media.graphics.vector.enable {
  #       "inkscape/templates/default.svg".source = ./config/inkscape/default-template.svg;
  #     })
  #     (mkIf desktop.apps.rofi.enable {
  #       "rofi/config.theme.rasi".source = ./config/rofi/config.rasi;
  #       "rofi/themes" = {
  #         source = ./config/rofi/themes;
  #         recursive = true;
  #       };
  #       "rofi/icons" = {
  #         source = ./config/rofi/icons;
  #         recursive = true;
  #       };
  #     })
  #   ];
  # })

  # (mkIf config.modules.desktop.hyprland.enable (import ./hyprland.nix args))
])
