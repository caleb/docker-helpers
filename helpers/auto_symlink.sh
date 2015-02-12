#/usr/bin/env bash

#
# Automatically links based on environment variables with a common prefix. All
# environment variables with the prefix "${prefix}_SYMLINK_" will be read as symlink
# declarations, each having the form "<symlink from> -> <symlink to>"
#
# If prefix is empty, the prefix "SYMLINK_" will be used
#
# The second parameter lets you decide which ln program to use, this should
# point to your GNU ln... this is generally only needed for running tests on
# a non-Linux machine.
#
# auto_symlink(prefix="", ln=ln)
#
# called as:
#
#     auto_symlink "NGINX"
#
# with the environment:
#
#     NGINX_SYMLINK_1=/some/dir -> /some/other/dir
#     NGINX_SYMLINK_2=/some/dir2 -> /some/other/dir2
#
# Symlinks will be created from
#
#    /some/dir to /some/other/dir
#    /some/dir2 to /some/other/dir2
#
# If the link is created with a "fat arrow" (=>) the destination is removed first
# with `rm -rf`
#

function trim() (
  local string="${1}"

  shopt -s extglob
  string="${string##*([[:space:]])}"
  string="${string%%*([[:space:]])}"

  echo -n "${string}"
)

function auto_symlink {
  if [ -z "${1}" ]; then
    prefix="SYMLINK"
  else
    prefix="${1}_SYMLINK"
  fi

  ln="${2:-ln}"

  if [ -n "$(which gsed)" ]; then
    sed="gsed"
  else
    sed="sed"
  fi

  # if a "default link is given, give it a name under the prefix"
  if [ -n "${!prefix}" ]; then
    export "${prefix}__DEFAULT__"="${!prefix}"
  fi

  for var in $(compgen -v); do
    if [[ "${var}" =~ ^${prefix}_(.*)$ ]]; then
      link_suffix="${BASH_REMATCH[1]}"
      link="${!var}"

      # Replace the double colons with a fat arrow
      link="$(echo "${link}" | "${sed}" -E -e 's/::(\s*\/)/=>\1/')"

      if [[ "${link}" =~ ^(.*)([=-]\>|:)(.*)$ ]]; then
        from="${BASH_REMATCH[1]}"
        to="${BASH_REMATCH[3]}"
        arrow="${BASH_REMATCH[2]}"

        from="$(trim "${from}")"
        to="$(trim "${to}")"
        arrow="$(trim "${arrow}")"

        if [ -z "${from}" ] || [ -z "${to}" ]; then
          echo "A link must be in the form \"<from> -> <to>\" or \"<from> => <to>\""
          exit 1
        else
          if [ "${arrow}" = "=>" ] || [ "${arrow}" = "::" ]; then
            rm -rf "${to}"
          elif [ -e "${to}" ]; then
            echo "The destination (${to}) already exists, remove it or use the fat arrow (=>) or double colons (::) to automatically remove it when linked" >&2
            exit 1
          fi

          "${ln}" -f -s -n "${from}" "${to}"
        fi
      fi
    fi
  done
}
