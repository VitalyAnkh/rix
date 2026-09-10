# test/nixos/hosts.nix --- tests for hosts/
#
# Every live host in hosts/ is applied and evaluated here, without $HEYENV and
# without --impure: evalHost fabricates the `hey` argument and routes the host
# through the same mkHostModules that mkFlake uses.
#
# testEveryHostEvaluates is the load-bearing one. It forces each host's
# system.build.toplevel down to its derivation path, which drags the whole
# configuration through evaluation -- assertions, type checks, unbound
# variables and all -- without building anything.

{ applyHost, evalHost, evalHost', hosts, lib, ... }:

with lib;
let
  # Hosts that cannot be evaluated right now. Each entry names an upstream
  # rename that needs a hardware decision, which is not the test suite's call
  # to make, so they are quarantined rather than guessed at.
  #
  # Neither failure is catchable: builtins.tryEval traps neither a missing
  # attribute nor an unbound variable, so a broken host here would take the
  # whole aggregate down rather than reporting as one failed test. Hence a
  # static list.
  #
  # Removing a host from this list is how you put it back under test.
  #
  # TODO htpc: nixos-hardware dropped common-cpu-intel-skylake and
  #   common-gpu-nvidia-maxwell. The surviving modules are common-cpu-intel
  #   and common-gpu-nvidia{,-nonprime,-sync}; which nvidia module is right
  #   depends on the card.
  # TODO soba: same common-cpu-intel-skylake, plus common-gpu-nvidia-pascal.
  broken = [ "htpc" "soba" ];

  live = removeAttrs hosts broken;

  # Configurations as written. Safe to read options off, but not to force
  # system.build.toplevel, because that forces config.assertions -- see below.
  configs = mapAttrs evalHost live;

  # modules/agenix.nix asserts that /etc/ssh/host_ed25519 exists whenever a
  # host declares any secrets, using builtins.pathExists on an absolute path
  # outside the store. Pure evaluation cannot see that file, so the assertion
  # fails for every host with a secrets/ directory, which is most of them.
  #
  # Emptying age.secrets satisfies the assertion's own escape hatch
  # (`age.secrets == {} || ...`) and is narrower than mkForce'ing the whole
  # assertion list, which would also throw away the user.name assertion in
  # default.nix. What age.secrets actually contains is asserted separately,
  # off `configs`, where assertions are never forced.
  buildable = mapAttrs (evalHost' [{ age.secrets = mkForce {}; }]) live;

  forEachHost = f: mapAttrs (_: f) configs;
in {
  # Guards the quarantine itself. If a host appears or disappears, this fails
  # and forces a look at the `broken` list above rather than letting a new host
  # go quietly untested.
  testAllHostsAreDiscovered = {
    expr = attrNames hosts;
    expected = [ "harusame" "htpc" "ramen" "soba" "udon" ];
  };

  testQuarantinedHostsAreExcluded = {
    expr = attrNames live;
    expected = [ "harusame" "ramen" "udon" ];
  };

  # There is no aarch64 or server host yet, despite modules/profiles/role/
  # carrying server.nix, vm.nix and platform/linode.nix. When that changes,
  # this test and the meta.platforms in ./default.nix both need revisiting.
  #
  # Read off the applied host, not off the evaluated config: nixosSystem is
  # handed a prebuilt nixpkgs via nixpkgs.pkgs, which leaves
  # nixpkgs.hostPlatform undefined and would make the evaluated answer say
  # nothing about what the host declared.
  testEveryHostDeclaresX86 = {
    expr = mapAttrs (n: h: (applyHost n h).host.system) live;
    expected = {
      harusame = "x86_64-linux";
      ramen    = "x86_64-linux";
      udon     = "x86_64-linux";
    };
  };

  # mkHostModules defaults networking.hostName to the host's directory name,
  # which is what makes `hey sync --host X` line up with hosts/X/.
  testHostNamesFollowDirectoryNames = {
    expr = forEachHost (c: c.networking.hostName);
    expected = {
      harusame = "harusame";
      ramen    = "ramen";
      udon     = "udon";
    };
  };

  testEveryHostSetsRoleAndUser = {
    expr = forEachHost (c: { inherit (c.modules.profiles) role user; });
    expected = {
      harusame = { role = "workstation"; user = "hlissner"; };
      ramen    = { role = "workstation"; user = "hlissner"; };
      udon     = { role = "workstation"; user = "hlissner"; };
    };
  };

  # Every host must define its own root filesystem. The mkDefault in
  # default.nix exists only to keep `nix flake check` happy on a host that has
  # not been given hardware config yet, and a real host relying on it would
  # boot the wrong disk.
  testEveryHostDefinesItsRootFilesystem = {
    expr = forEachHost (c: c.fileSystems."/".fsType);
    expected = {
      harusame = "ext4";
      ramen    = "ext4";
      udon     = "ext4";
    };
  };

  ## Secrets wiring, asserted off the unmodified configurations.

  # agenix.nix walks the host's and the shared secrets directory and turns
  # every *.age named in a secrets.nix into an age.secrets entry, stripping the
  # suffix. The .age files themselves are never read here.
  testHostSecretsAreDiscovered = {
    expr = forEachHost (c: attrNames c.age.secrets);
    expected = {
      harusame = [ "wg0PrivateKey" ];
      ramen    = [ "wg0PrivateKey" ];
      udon     = [];
    };
  };

  testSecretsAreOwnedByTheHostUser = {
    expr = (configs.ramen.age.secrets.wg0PrivateKey).owner;
    expected = "hlissner";
  };

  # The one that actually evaluates each configuration end to end.
  testEveryHostEvaluates = {
    expr = mapAttrs (_: c: isString c.system.build.toplevel.drvPath) buildable;
    expected = {
      harusame = true;
      ramen    = true;
      udon     = true;
    };
  };
}
