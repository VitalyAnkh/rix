# profiles/role/server.nix
#
# Used for headless servers, at home or abroad, with more
# security/automation-minded configuration.

{ self, lib, pkgs, ... }:

with lib;
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  systemd = {
    services.clear-log = {
      description = "Clear >1 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=21d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
  };

  powerManagement.cpuFreqGovernor = mkDefault "ondemand";
  virtualisation.docker.enableOnBoot = mkDefault true;
  power.ups.mode = mkDefault "netclient";

  ## Security tweaks
  boot.kernelPackages = mkDefault pkgs.linuxKernel.packages.linux_6_1_hardened;
  # Prevent replacing the running kernel w/o reboot
  security.protectKernelImage = true;
}