#!/bin/sh
set -u

die() {
   echo "${1:+died: }${1:-died.}" 1>&2
   exit ${2:-2}
}

cat_to_file() {
   local f
   f="${O:?}/${1:?}"

   [ ! -f "${f}" ] || die "outfile ${f} exists"
   cat > "${f}" || die "failed to write ${f}"
}

parse_file_do() {
   local func infile line

   infile="${1:?}"
   func="${2:?}"
   set --

   set -f
   while read -r line; do
      set -- ${line}
      case "${1-}" in
         ''|'#'*)
            true
         ;;
         *)
            ${func:?} "${@}"
         ;;
      esac
   done < "${infile}"
}

preparse() {
   if [ $# -lt 1 ] || [ $# -gt 2 ]; then
      echo "bad input: ${line}" 1>&2
      return 2
   fi

   case "${2-}" in
      '')
         case "${1}" in
            *:*:*:*:*:*)
               ifname=
               mac="${1}"
            ;;
            *)
               echo "bad input: not a mac addr: ${1} (${line})" 1>&2
               return 1
            ;;
         esac
      ;;
      *:*:*:*:*:*)
         # ^ not super accurate
         ifname="${1}"
         mac="${2}"
      ;;
      *)
         echo "bad input: not a mac addr: ${2} (${line})" 1>&2
         return 1
      ;;
   esac
}

create_entries() {
   local ifname mac outfile

   preparse "$@" || return 0
   : ${mac:?}

   case "${ifname}" in
      '')
         ifname=ether${autoid}
         autoid=$(( ${autoid} + 1 )) # overflows
      ;;
      '-')
         die "'keep' ifname is not implemented."
      ;;
   esac

   cat_to_file "20-${ifname}.link" << EOF
[Match]
MACAddress=${mac}

[Link]
Name=${ifname}
NamePolicy=
EOF
}


parse_file_create_entries() {
   parse_file_do "${1:?}" create_entries
}


autoid=0
O="${1:?}"
shift && mkdir -p -- "${O}" || die

while [ $# -gt 0 ]; do
   [ -f "${1}" ] || die "mactab file not found: ${1}"
   parse_file_create_entries "${1}" || die
   shift || die
done
