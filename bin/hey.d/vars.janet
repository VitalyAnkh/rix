#!/usr/bin/env janet
# Get or set session or persistent state in userspace.
#
# SYNOPSIS:
#   vars [-g]
#   vars [-g] get VAR
#   vars [-g] set VAR VALUE
#
# OPTIONS:
#   -g
#     Operate on persistent (global) vars.
#
# ARGUMENTS:
#   1 COMMAND
#     get     -- Print a var.
#     set     -- Assign a var.
#   2 VAR @vars
#   3 VALUE

(use hey)
(use hey/cmd)
(import hey/vars)

(defcmd vars [_ cmd & args &opts global? -g]
  (echo ;(case cmd
          "get" [(vars/get (first args) global?)]
          "set" [(vars/set (in args 0) (get args 1) global?)]
          nil   (vars/list global?))))
