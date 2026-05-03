# lib/hey/bw.janet
#
# An API for interacting with the Bitwarden CLI.

(use ./.)
(import spork/json)

(defmacro with-session [& body]
  ~(with-envvars ["BW_SESSION" (or (os/getenv "BW_SESSION")
                                   ($<_ bw unlock --raw))]
     ,;body))

(defn get [type query &opt id]
  (json/decode ($<_ bw get ,(string type) ,query
                    ,;(if id ["--itemid" id] [])
                    "--raw")
               :keywords true))
