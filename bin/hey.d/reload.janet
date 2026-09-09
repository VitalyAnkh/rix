#!/usr/bin/env janet
# Reload running services.
#
# SYNOPSIS:
#   reload
#
# DESCRIPTION:
#   Triggers the onReload hook, which restarts or reloads whatever the active
#   host and window manager have registered for it.

(use hey)
(use hey/cmd)
(import hey/sys)

(defcmd reload [_]
  (echof :g "Reloading %s..." (os/getenv "XDG_CURRENT_DESKTOP"))
  (when (hey! hook onReload -f -v)
    (sys/notify "Finished reloading system" :icon 'checkmark :sound 'notify))
  (echo :check "Done!"))
