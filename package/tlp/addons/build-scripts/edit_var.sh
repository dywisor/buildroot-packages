#!/bin/sh -u
#
#  Edits a variable in TLP's source files.
#
#  Usage:
#
#   * <script> <TLP src root> <varname> <value> [<old value>]
#
#      Replaces occurences of ""(readonly|declare)? <varname>=...""
#      with ""(readonly|declare)? <varname>=<value>"".
#      <value> defaults to "".
#
#      Also replaces occurences of <old value> with <value>
#      if <old value> is set and not empty (for man pages etc.).
#      !!! Use with care. For example, setting <old value> = "e"
#          would replace any "e" with <value>.
#
#
# Example Usage:
#   * <script> $S CONFFILE /etc/conf.d/tlp /etc/default/tlp
#
# Limitations:
#   * can only edit ""simple"" variables, that is
#    >>> VAR=value
#    >>> readonly VAR=value
#    >>> declare VAR=value
#
#    -> no multi line entries
#       >>> V\
#       >>> AR="wo\
#       >>> rd1
#       >>> word2"
#    -> only one var per line
#    -> no bash arrays etc.
#
[ -z "${BASH_VERSION-}" ] || set -o posix

die() { echo "${1:+died: }${1:-died.}" 1>&2; exit ${2:-2}; }


: ${X_LS_FILES:="./scripts/list_src_files.sh"}

src_root="${1-}"
varname="${2-}"
value="${3-}"
old_value="${4-}"

[ -n "${src_root}"   ] && cd "${src_root}" || die "invalid <src root>" 64
[ -n "${varname}"    ] || die "<varname> must not be empty." 64
[ -x "${X_LS_FILES}" ] || die "${X_LS_FILES} not found." 5

# get_var_repl_regex ( varname, newval, **v0! )
get_var_repl_regex() {
   v0=
   local match_expr
   # COULDFIX: also edits var="...' statements
   #            (but this should be a minor issue)
   #
   # regex groups:
   # 1: keyword    -- "readonly", "declare" or empty (whitespace preserved)
   # 2: varname    -- "varname="
   # 3: quote char -- ", ' or empty (discarded; " is used as quote char)
   # 4: old value  --
   # 5: quote char -- see 3
   # 6: remainder  -- only whitespace and end-of-line comments allowed (will be discarded)
   #
match_expr="^(\s*readonly\s+|\s*declare\s+|\s*)(${1}=)\
([\'\"])?(.*?[^\'\"])?([\'\"])?(\s*|\s*#.+)\$"

   v0="s@${match_expr}@\1\2\"${2}\"@"
}



# set argv := sed expressions
##set -- -e "s@${match_expr}@\1\2\"${value}\"@"
get_var_repl_regex "${varname}" "${value}"
set -- -e "${v0}"
[ -z "${old_value}" ] || set -- "$@" -e "s@${old_value}@${value}@g"

# PWD is src root
${X_LS_FILES} ./ | xargs sed -i -r "$@" --
