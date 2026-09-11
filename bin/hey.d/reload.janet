#!/usr/bin/env janet
# Reload running services.
#
# SYNOPSIS:
#   reload [@AREA]
#
# DESCRIPTION:
#   Triggers the onReload hook, which restarts or reloads whatever the active
#   host and window manager have registered for it. Given an AREA, only that
#   area's handler is triggered (see hey hook).
#
# ARGUMENTS:
#   1 AREA @hook-areas

(use hey)
(use hey/cmd)
(import hey/sys)

(defcmd reload [_ area]
  (def area (if (and area (not (string/has-prefix? "@" area)))
              (string "@" area)
              area))
  (echof :g "Reloading %s..." (or area (os/getenv "XDG_CURRENT_DESKTOP")))
  (when (hey! hook ,;(opts area) onReload -f -v)
    (sys/notify "Finished reloading system" :icon 'checkmark :sound 'notify))
  (echo :check "Done!"))
