#!/usr/bin/env janet
# Run the Hey and/or NixOS test suites.
#
# A suite name after `nixos` builds that suite alone, which is much faster to
# iterate on than the whole set:
#
# SYNOPSIS:
#   test [SUITE [ARGS...]]
#   test [-l|--list]
#
# OPTIONS:
#   -l, --list
#     List all test suites.
#
# ARGUMENTS:
#   1 SUITE
#     hey    -- Run the Janet suite in test/hey through judge.
#     nixos  -- Run the NixOS suite in test/nixos through nix build.
#   * ARGS @test-arg

(use hey)
(use hey/cmd)
(use sh)

# The suites are addressed per-system, and nix has no "current system" in a
# flake attrpath, so it has to be asked.
(defn- system []
  ($<_ nix eval --raw --impure --expr "builtins.currentSystem"))

(defn- check-attr [&opt suite]
  (string (path :home) "#checks." (system) ".nixos"
          (if suite (string ".passthru." suite) "")))

(defn- suites []
  (string/split
   "\n"
   ($<_ nix eval --raw --no-warn-dirty ,(check-attr)
        --apply "d: builtins.concatStringsSep \"\\n\" (builtins.attrNames d.passthru)")))

(defn- run-hey [args]
  (echo :g "> Running the Hey suite...")
  (flush)
  (do? $? judge ,(path :test "hey") ,;args))

(defn- run-nixos [args]
  (def suite (first args))
  # Checked up front, because nix's own message for a bad attrpath names three
  # attributes that don't exist and never mentions the suite list.
  (when (and suite (not (index-of suite (suites))))
    (abort "Unknown NixOS suite: %s (see hey test -l)" suite))
  (echo :g "> Running the NixOS suite...")
  (flush)
  # No --impure and no HEYENV: test/nixos fabricates the `hey` argument itself
  # rather than going through nixosConfigurations, precisely so this stays a
  # pure build. See test/nixos/_lib.nix.
  #
  # A passing nix build says nothing at all, which next to judge's "N passed"
  # reads like the suite never ran, hence the confirmation.
  (if (do? $? nix build --no-link --no-warn-dirty ,(check-attr suite))
    (do (echo :check (if suite
                       (string "NixOS suite passed: " suite)
                       "NixOS suites passed"))
        true)
    (abort "NixOS suite failed")))

(defcmd test [_ suite & args &opts list? [-l --list]]
  (when list?
    (echo ;(suites))
    (break))
  (case* suite
    nil   (and (run-hey []) (run-nixos []))
    "hey" (run-hey args)
    ["nixos" "nix"] (run-nixos args)
    (abort "Unknown suite: %s" suite)))
