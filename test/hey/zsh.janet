#!/usr/bin/env janet

(use judge)
(use sh)
(import hey)

# Ensure zsh helpers are available to these tests.
(def- autoload-hey
  (let [dir (hey/path :lib "zsh")]
    (string "fpath=( " dir " ); autoload -Uz ${fpath[1]}/hey.*(.:t); \"$@\"")))

(defmacro zsh [& args]
  ~(,(first args) zsh -c ,autoload-hey "hey-test"
    ,(string (get args 1)) ,;(slice args 2)))

(deftest hey.requires
  (def null (file/open "/dev/null"))
  (test (zsh $? hey.requires zsh bash sh) true)
  (test (zsh $? hey.requires zsh bash doesnotexist > [stderr null]) false)
  (test (zsh $? hey.requires doesnotexist > [stderr null]) false))

(deftest hey.do
  (test (zsh $<_ hey.do echo 10) "10")
  (hey/with-envvars ["HEYDRYRUN" "1"]
    (let [out @"" err @""]
      (zsh $<_ hey.do echo 10 > ,out > [stderr err])
      (test (deep-not= err @"") true)
      (test out @""))))
