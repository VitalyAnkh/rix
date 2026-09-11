#!/usr/bin/env janet
# The pure half of bin/hey.d/hook.janet's area handling. Resolution itself
# reads config/, so it's left to `hey hook -l`.

(use judge)
(import ../../bin/hey.d/hook :as hook)


(deftest hook/parse-area
  (deftest "A leading sigil scopes the hook and shifts everything down one"
    (test (hook/parse-area "@zsh" ["onReload" "--now"])
          ["zsh" "onReload" ["--now"]])
    (test (hook/parse-area "@zsh" []) ["zsh" nil []]))

  (deftest "Without one, the arguments pass through untouched"
    (test (hook/parse-area "onReload" ["--now"]) [nil "onReload" ["--now"]])
    (test (hook/parse-area nil []) [nil nil []])))

(deftest hook/sort-areas
  (deftest "The window manager runs first, the rest alphabetically"
    (test (hook/sort-areas ["zsh" "hypr" "git"] "hypr")
          ["hypr" "git" "zsh" "host"]))

  (deftest "host is always known, and never twice"
    (test (hook/sort-areas ["host" "zsh"] "zsh") ["zsh" "host"])
    (test (hook/sort-areas [] nil) ["host"]))

  (deftest "An absent or unset window manager forfeits its slot"
    (test (hook/sort-areas ["zsh" "git"] "hypr") ["git" "zsh" "host"])
    (test (hook/sort-areas ["zsh" "git"] nil) ["git" "zsh" "host"])))
