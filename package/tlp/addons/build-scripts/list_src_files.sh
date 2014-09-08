#!/bin/sh -u
#
#  Lists editable source files (one per line)
#
#  Usage: <script> [<src root>]
#
#  Environment variables:
#  * TLP_RE_EXCLUDE overrides RE_EXCLUDE
#  * TLP_RE_EXCLUDE_APPEND
#     is appended to RE_EXCLUDE (leading "|" gets stripped)
#
#  Exit Code: non-zero on failure
#
DEFAULT_RE_EXCLUDE="\
${0##*/}|COPYING|LICENSE|Makefile|default|tpacpi-bat|\
.*\.(rules|service|upstart|init|bash_comp.*)"

RE_EXCLUDE="${TLP_RE_EXCLUDE-${DEFAULT_RE_EXCLUDE}}"
if [ -n "${TLP_RE_EXCLUDE_APPEND-}" ]; then
   RE_EXCLUDE="${RE_EXCLUDE}|${TLP_RE_EXCLUDE_APPEND#|}"
fi

[ -z "${1-}" ] || cd "${1}" || { echo "invalid <src root>" 1>&2; exit 1; }
find ./ ./man/ \
   -maxdepth 1 -type f -print | grep -vxE -- "(\./)?(${RE_EXCLUDE})"
