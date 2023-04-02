# modules/home-manager.nix
#
# I'm sure I'm reinventing wheels by avoiding home-manager's other capabilities
# and using it solely as a $HOME file/link manager, but it's already an ordeal
# to maintain this config on top of nixpkgs and its rapidly-shifting
# idiosynchrosies (though it's still better than what I had before NixOS). Add
# home-manager to the mix and it becomes too much, so I treat it as little more
# than a library, and simply write my own modules.

{ self, lib, config, options, home-manager, pkgs, ... }:

with lib;
with self.lib;
{
  imports = [
    self.modules.home-manager.default
  ];

  options = {
    home = with types; {
      file       = mkOpt' attrs {} "Files to place directly in $HOME";
      configFile = mkOpt' attrs {} "Files to place in $XDG_CONFIG_HOME";
      dataFile   = mkOpt' attrs {} "Files to place in $XDG_DATA_HOME";
      fakeFile   = mkOpt' attrs {} "Files to place in $XDG_FAKE_HOME";
    };
  };

  config = {
    # Install user packages to /etc/profiles instead. Necessary for
    # nixos-rebuild build-vm to work.
    home-manager = {
      useUserPackages = true;

      # I only need a subset of home-manager's capabilities. That is, access to
      # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
      # files easily to my $HOME, but 'home-manager.users.hlissner.home.file.*'
      # is much too long and harder to maintain, so I've made aliases in:
      #
      #   home.file        ->  home-manager.users.hlissner.home.file
      #   home.configFile  ->  home-manager.users.hlissner.home.xdg.configFile
      #   home.dataFile    ->  home-manager.users.hlissner.home.xdg.dataFile
      users.${config.user.name} = {
        home = {
          file = mkAliasDefinitions options.home.file;
          # Necessary for home-manager to work with flakes, otherwise it will
          # look for a nixpkgs channel.
          stateVersion = config.system.stateVersion;
        };
        xdg = {
          enable = true;
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile   = mkAliasDefinitions options.home.dataFile;
        };
      };
    };

    # See XDG_FAKE_HOME in modules/xdg.nix for details.
    home.file =
      mapAttrs' (k: v: nameValuePair "${config.xdg.fakeHomeDir}/${k}" v)
        config.home.fakeFile;
  };
}
