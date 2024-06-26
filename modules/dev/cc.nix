# modules/dev/cc.nix --- C & C++
#
# I like C. I tolerate C++. I like++ C with a few choice C++ features tacked on.
# Liking C/C++ seems to be an unpopular opinion, so it's my guilty secret.
# Don't tell anyone pls.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.cc;
in {
  options.modules.dev.cc = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        clang
        gcc
        bear
        cmake
        llvmPackages.libcxx

        # Respect XDG, damn it!
        (mkWrapper gdb ''
          wrapProgram "$out/bin/gdb" --add-flags '-q -x "$XDG_CONFIG_HOME/gdb/init"'
        '')
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
