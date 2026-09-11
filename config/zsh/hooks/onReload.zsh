#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload
#
# SYNOPSIS:
#   Triggered by 'hey reload'

rm -frv "$ZGEN_DIR"
rm -frv "$XDG_CACHE_HOME"/zsh/*(DN)
rm -fv "$ZDOTDIR"/**/*.zwc(D.N)
