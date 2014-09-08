#!/bin/sh
#
#  Usage: gen-tlp-devlist-prog.sh <prog type> [<lib dir> [<lib name>]]
#
#
#  Generates a tlp-devlist wrapper and prints it to stdout.
#  Hardwires the script to <lib dir> if specified,
#  else uses upstream's libdir lookup.
#

prog_type="${1:?}"; prog_type="${prog_type#tlp-}"
shift

prog_func=
prog=

case "${prog_type}" in
   pcilist|pci)
      prog_type=pcilist
      prog_desc="list pci devices with runtime pm mode and device class"
   ;;
   usblist|usb)
      prog_type=usblist
      prog_desc="list usb device info with autosuspend attributes"
   ;;
   *)
      echo "unknown devlist prog: ${prog_type}" 1>&2
      prog_desc=
   ;;
esac

: ${prog_func:="tlp_${prog_type}"}
: ${prog:="tlp-${prog_type}"}

cat << EOF
#!/bin/sh -u
# ${prog} [sh]${prog_desc:+ - ${prog_desc}}

EOF

if [ -n "${1-}" ]; then
cat << EOF
. "${1}/${2:-tlp-devlist-functions}" -- || exit 8
EOF

else
   cat << EOF
readonly LIBDIRS="/usr/lib/tlp-pm /usr/lib64/tlp-pm"
readonly LIBS="${2:-tlp-devlist-functions}"

# --- Locate and source libraries
for libdir in \$LIBDIRS; do [ -d \$libdir ] && break; done
[ -d \$libdir ] || exit 9

for lib in \$LIBS; do
    [ -f \$libdir/\$lib ] || exit 9
    . \$libdir/\$lib -- || exit 8
done
EOF

fi

cat << EOF

${prog_func} "\$@"
EOF
