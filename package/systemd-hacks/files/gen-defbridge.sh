#!/bin/sh
set -u

die() {
   echo "${1:+died: }${1:-died.}" 1>&2
   exit ${2:-2}
}

peek_args() {
   local arg
   arg="${1:?}"

   v0=
   v1=
   while [ $# -gt 1 ]; do
      doshift=$(( ${doshift} + 1 ))
      case "${2}" in
         '--')
            return 0
         ;;
         '')
            die "empty str not allowed for option ${arg}"
         ;;
         *)
            v0="${v0:+${v0} }${2}"
            v1="${2}"
         ;;
      esac
      shift
   done

   die "unterminated option list for ${arg}"
}


unset -v O name ifaces dhcp mac

while [ $# -gt 0 ]; do
   doshift=1
   case "${1}" in
      "-O")
         O="${2:?}"
         doshift=2
      ;;
      "--bridge-name")
         peek_args "$@"
         name="${v1}"
      ;;
      "--bridge-interfaces")
         peek_args "$@"
         ifaces="${v0}"
      ;;
      "--dhcp")
         peek_args "$@"
         dhcp="${v1}"
      ;;
      "--macaddr")
         peek_args "$@"
         mac="${v1}"
      ;;
      *)
         die "cannot parse arg: ${1}"
      ;;
   esac
   shift ${doshift} || die
done

: ${O=}
: ${name:=br0}
: ${ifaces="eth*"}
: ${dhcp=both}
: ${mac=}

if [ -n "${O}" ]; then
   mkdir -- "${O}" || die
   cat_to_file() { cat > "${O:?}/${1:?}" || die; }
else
   cat_to_file() {
      echo "*** ${1:?} ***"
      cat
      echo "***"
      echo
   }
fi

cat_to_file 30-${name}.netdev << EOF
[NetDev]
Name=${name}
Kind=bridge
MACAddress=${mac}
EOF

cat_to_file 35-${name}-members.network << EOF
[Match]
Name=${ifaces}

[Network]
Bridge=${name}
EOF

cat_to_file 40-${name}.network << EOF
[Match]
Name=${name}

[Network]
DHCP=${dhcp}

[DHCP]
CriticalConnection=yes
EOF
