#!/usr/bin/env janet
# Trigger an event.
#
# A hook is scoped to an area: a directory under config/ that owns a hooks/
# subdirectory (plus the reserved area "host", for hosts/$HOST/hooks). Without
# an area, every area is triggered, ordered by the active window manager first,
# then alphabetically.
#
# Executes each of the following, in this order. NAME means the first of
# NAME.janet, NAME.zsh, NAME.sh or NAME that exists:
#
# - ~/.config/$AREA/hooks/all --$HOOK
# - ~/.config/$AREA/hooks/$HOOK
# - hosts/$HOST/hooks/$HOOK
# - config/$AREA/hooks/all --$HOOK
# - config/$AREA/hooks/$HOOK
# - $XDG_DATA_HOME/hey/hooks.d/$HOOK.d/*
#
# The last has no area, so it is skipped when one is given.
#
# Will no-op if the hook was already triggered.
#
# Run hey hook -l for a list of all known hooks on your system.
#
# SYNOPSIS:
#   hook [-f] [-v] [@AREA] HOOK [ARGS...]
#   hook [-l|--list] [@AREA] [HOOK [ARGS...]]
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
#   ** ARGS @hook-arg

(use hey)
(use hey/cmd)
(import hey/vars)

(def- *vars* (vars/new (:dir vars/temp :hook)))

(defn parse-area
  ``Split a leading @AREA off HOOK, returning [AREA HOOK ARGS]. Without the
  sigil, AREA is nil and the arguments are returned untouched.``
  [hook args]
  (if (and hook (string/has-prefix? "@" hook))
    [(string/slice hook 1) (first args) (tuple ;(drop 1 args))]
    [nil hook (tuple ;args)]))

(defn sort-areas
  ``Order area NAMES with WM first, the rest alphabetically, then host, which is
  always known because it names hosts/$HOST/hooks.``
  [names &opt wm]
  (let [names (distinct (filter |(not= $ "host") names))]
    [;(if (index-of wm names) [wm] [])
     ;(sorted (filter |(not= $ wm) names))
     "host"]))

(defn- areas [&opt area]
  (let [names (sort-areas
               (filter |(path/directory? (path :config $ "hooks"))
                       (or (ignore-errors (os/dir (path :config))) []))
               (ignore-errors (path/basename (path :wm))))]
    (cond (nil? area) names
          (index-of area names) [area]
          (abort "Unknown area: %s" area))))

(defn- area-dirs [names]
  ``The hooks/ directories of NAMES, grouped as [LIVE HOST REPO]. The host's
  hooks aren't user-editable elsewhere, so it has no live counterpart.``
  (let [cfgs (filter |(not= $ "host") names)]
    [(map |(path/xdg :config $ "hooks") cfgs)
     (if (index-of "host" names) [(path :host "hooks")] [])
     (map |(path :config $ "hooks") cfgs)]))

(defn- hooks [area hook args]
  (let [[live host repo] (area-dirs (areas area))]
    (each f [;(catseq [dir :in live]
                [(resolve dir "all" (string "--" hook) ;args)
                 (resolve dir hook ;args)])
             ;(map |(resolve $ hook ;args) host)
             ;(catseq [dir :in repo]
                [(resolve dir "all" (string "--" hook) ;args)
                 (resolve dir hook ;args)])
             # Third party handlers (see modules/hey.nix) belong to no area.
             ;(if area []
                (map |[$ ;args]
                     (or (ignore-errors
                          (path/files-in (path :data "hooks.d" (string hook ".d"))))
                         [])))]
      (when (and f
                 (path/file? (first f))
                 (path/executable? (first f)))
        (yield f)))))

(defn- all-hooks [&opt area]
  (defn names-in [dir]
    (map |(path/no-ext $ ;*script-exts* ".d") (or (ignore-errors (os/dir dir)) [])))
  (let [names @{}
        [live host repo] (area-dirs (areas area))]
    (each dir [;live ;host ;repo]
      (each name (names-in dir)
        (unless (= name "all")  # fallthrough handler for all hooks
          (put names name true))))
    (unless area
      (each name (names-in (path :data "hooks.d"))
        (put names name true)))
    (sorted (keys names))))

(defcmd hook [_ hook & args &opts force? -f list? [-l --list] verbose? -v]
  (def [area hook args] (parse-area hook args))
  (when list?
    (if hook
      (echo ;(map first (coro (hooks area hook args))))
      (each name (all-hooks area)
        (let [paths (map first (coro (hooks area name args)))]
          (unless (empty? paths)
            (echo name)
            (echo ;(map |(string "  " $) paths))))))
    (break))
  (unless hook
    (abort "No hook specified"))
  (let [hash [;(if area [(string "@" area)] []) hook ;args]]
    (when (and (not force?) (deep= (:get *vars* :last) hash))
      (abort "Redundant hook triggered: %q" hash))
    (os/with-lock (path :runtime "hook.lock")  # don't clobber hooks
      (defer (unless (dryrun?) (:set *vars* :last hash))
        (var c 0)
        (each cmd (coro (hooks area hook args))
          (log "Hook: %s" (path/abbrev (first cmd)))
          (echof :g "Running %s..." (path/basename (first cmd)))
          (do? $? ,;cmd)
          (++ c))
        (echof :pass "Triggered %d hook(s) for: %q" c hash)))))
