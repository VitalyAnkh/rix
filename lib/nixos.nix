# lib/flakes.nix --- syntax sugar for flakes
#
# This may look a lot like what flake-parts, flake-utils(-plus), and/or digga
# offer. I reinvent the wheel because (besides flake-utils), they are too
# volatile to depend on. They see subtle and unannounced changes, often. Since I
# rely on this flake as a basis for 100+ systems, VMs, and containers, some of
# whom are mission-critical, I'd rather have a less polished API that I fully
# control than a robust one that I cannot predict, for maximum mobility. It's
# also a more valuable learning experience.

{ self, lib, attrs, modules }:

with builtins;
with lib;
with attrs;
with modules;
rec {
  mkApp = program: {
    inherit program;
    type = "app";
  };

  mkHey = {
    flake
  , dir
  , hostDir ? dir
  , args ? {}
  , packages ? {}
  , devShell ? {}
  , apps ? {}
  }: flake // {
    inherit args hostDir packages devShell apps;
    modules =
      filterMapAttrs
        (_: i: i ? nixosModules)
        (_: i: i.nixosModules)
        flake.inputs;
    dir =
      if dir != "" then dir
      else abort "No or invalid dir specified: ${dir}";
    binDir      = "${dir}/bin";
    libDir      = "${dir}/lib";
    configDir   = "${dir}/config";
    modulesDir  = "${dir}/modules";
  };

  mkHostModules = {
    host
  , hostName
  , pkgs
  , extraModules ? []
  }: [
    {
      nixpkgs.pkgs = pkgs;
      networking.hostName = mkDefault hostName;
    }
    ../.
  ]
  ++ (host.imports or [])
  ++ [ {
    modules = host.modules or {};
  } ]
  ++ [ (host.config or {}) (host.hardware or {}) ]
  ++ extraModules;

  # FIXME: Refactor me! (Use submodules?)
  mkFlake = {
    self
    , hey ? self
    , nixpkgs ? hey.inputs.nixpkgs
    , ...
  } @ inputs: {
    apps ? {}
    , checks ? {}
    , devShells ? {}
    , hosts ? {}
    , modules ? {}
    , overlays ? {}
    , packages ? {}
    , storage ? {}
    , systems
    , templates ? {}
    , ...
  } @ flake:
    let
      mkPkgs = system: pkgs: overlays: import pkgs {
        inherit system overlays;
        config.allowUnfree = true;
        # A number of packages depend on python 2.7, but nixpkgs errors out when
        # it is pulled, so...
        config.permittedInsecurePackages = [ "python-2.7.18.6" ];
      };

      # Processes external arguments that bin/hey will feed to this flake (using
      # a json payload in an envvar). The internal var is kept in lib to stop
      # 'nix flake check' from complaining more than it has to.
      args =
        let hargs = getEnv "HEYENV"; in
        if hargs == ""
        then abort "HEYENV envvar is missing"
        else fromJSON hargs;

      # This is the only impurity we allow into this flake, because there are
      # many times where it is more convenient to generate or seed dotfiles or
      # envvars with local (non-nix-store) paths instead, so I don't have to
      # rebuild each time I change/swap them out.
      nixosConfigurations = mapAttrs (hostName: { path, config }:
        # TODO: Replace with a submodule
        let
          nixosModules =
            filterMapAttrs
              (_: i: i ? nixosModules)
              (_: i: i.nixosModules)
              inputs;
          self' = mkHey {
            inherit args;
            flake = self;
            dir = toString self;
            hostDir = path;
            packages = self.packages.${host.system};
            devShell = self.devShell.${host.system};
            apps = self.apps.${host.system};
          };
          hey' = mkHey {
            inherit args;
            flake = hey;
            dir = args.path;
            hostDir = path;
            packages = hey.packages.${host.system};
            devShell = hey.devShell.${host.system};
            apps = hey.apps.${host.system};
          };
          host = config {
            inherit args lib nixosModules;
            hey = hey';
          };
          pkgs = mkPkgs host.system nixpkgs (attrValues overlays);
        in
          nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs.self = self';
            specialArgs.hey = hey';
            modules = mkHostModules {
              inherit host pkgs;
              hostName = args.host or hostName;
            };
          }) hosts;
      perSystem = map (system:
        let withPkgs = extraArgs: pkgs: packageAttrs:
              mapFilterAttrs
                (_: v: pkgs.callPackage v ({ self = self.packages.${system}; } // extraArgs))
                (_: v: !(v ? meta.platforms) || (elem system v.meta.platforms))
                packageAttrs;
            pkgs = mkPkgs system nixpkgs (attrValues overlays);
        in filterAttrs (_: v: v.${system} != {}) {
          apps.${system} = apps;
          # test/nixos needs this flake's own inputs and 'self' is already taken
          # by the package set.
          checks.${system} = withPkgs { flake = self; } pkgs checks;
          devShells.${system} = withPkgs {} pkgs devShells;
          packages.${system} = withPkgs {} pkgs packages;
        }) systems;
    in
      (filterAttrs (n: _: !elem n [
        "apps" "bundlers" "checks" "devices" "devShells" "hosts" "modules"
        "packages" "storage" "systems"
      ]) flake) // {
          inherit nixosConfigurations;
          nixosModules = modules;

          # To parameterize this flake (more so for flakes derived from this
          # one) I rely on bin/hey (my nix{,os} CLI/wrapper) to emulate
          # --arg/--argstr options. 'dir' and 'host' are special though, and
          # communicated using hey's -f/--flake and --host options:
          #
          #   hey sync -f /etc/nixos#soba
          #   hey sync -f /etc/nixos --host soba
          #
          # The magic that allows this lives in mkFlake, but requires --impure
          # mode. Sorry hermetic purists!
          _heyArgs = args;
      } // (mergeAttrs' perSystem);
}
