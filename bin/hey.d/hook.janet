#!/usr/bin/env janet
# Trigger an event.
#
# Executes each of the following, in this order. NAME means the first of
# NAME.janet, NAME.zsh, NAME.sh or NAME that exists:
#
# - ~/.config/$WM/hooks/all --$HOOK
# - ~/.config/$WM/hooks/$HOOK
# - hosts/$HOST/hooks/$HOOK
# - config/$WM/hooks/all --$HOOK
# - config/$WM/hooks/$HOOK
# - $XDG_DATA_HOME/hey/hooks.d/$HOOK.d/*
#
# Will no-op if the hook was already triggered.
#
# Run hey hook -l for a list of all known hooks on your system.
#
# SYNOPSIS:
#   hook [-f] [-v] HOOK [ARGS...]
#   hook [-l|--list] [HOOK [ARGS...]]
#
# OPTIONS:
#   -f
#     Trigger the hook even if it is redundant.
#   -l [HOOK], --list [HOOK]
#     List the scripts that would be run, instead of running them. Without a
#     HOOK, list them for every known hook, grouped by hook.
#   -v
#     Be verbose.
#
# ARGUMENTS:
#   1 HOOK @hooks
#   ** ARGS @default

(use hey)
(use hey/cmd)
(import hey/vars)

(def- *vars* (vars/new (:dir vars/temp :hook)))
(def- *exts* [".janet" ".zsh" ".sh" ".d"])

(defn- hooks [hook args]
  (let [wmdir (path :wm "hooks")
        wmdir* (path :wm* "hooks")]
    (each f [(resolve wmdir* "all" (string "--" hook) ;args)
             (resolve wmdir* hook ;args)
             (resolve (path :host "hooks") hook ;args)
             (resolve wmdir "all" (string "--" hook) ;args)
             (resolve wmdir hook ;args)
             ;(map |[$ ;args]
                   (or (ignore-errors
                        (path/files-in (path :data "hooks.d" (string hook ".d"))))
                       []))]
      (when (and f
                 (path/file? (first f))
                 (path/executable? (first f)))
        (yield f)))))

(defn- all-hooks []
  (defn names-in [dir]
    (map |(path/no-ext $ ;*exts*) (or (ignore-errors (os/dir dir)) [])))
  (let [names @{}]
    (each dir [(path :wm* "hooks")
               (path :host "hooks")
               (path :wm "hooks")]
      (each name (names-in dir)
        (unless (= name "all")  # fallthrough handler for all hooks
          (put names name true))))
    (each name (names-in (path :data "hooks.d"))
      (put names name true))
    (sorted (keys names))))

(defcmd hook [_ hook & args &opts force? -f list? [-l --list] verbose? -v]
  (when list?
    (if hook
      (echo ;(map first (coro (hooks hook args))))
      (each name (all-hooks)
        (let [paths (map first (coro (hooks name args)))]
          (unless (empty? paths)
            (echo name)
            (echo ;(map |(string "  " $) paths))))))
    (break))
  (unless hook
    (abort "No hook specified"))
  (let [hash [hook ;args]]
    (when (and (not force?) (deep= (:get *vars* :last) hash))
      (abort "Redundant hook triggered: %q" hash))
    (os/with-lock (path :runtime "hook.lock")  # don't clobber hooks
      (defer (unless (dryrun?) (:set *vars* :last hash))
        (var c 0)
        (each cmd (coro (hooks hook args))
          (log "Hook: %s" (path/abbrev (first cmd)))
          (echof :g "Running %s..." (path/basename (first cmd)))
          (do? $? ,;cmd)
          (++ c))
        (echof :pass "Triggered %d hook(s) for: %q" c hash)))))
