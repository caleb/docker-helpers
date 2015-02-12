#/usr/bin/env bash

#
# Automatically links based on environment variables with a common prefix. All
# environment variables with the prefix "${prefix}_SYMLINK_" will be read as symlink
# declarations, each having the form "<symlink from>:<symlink to>"
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
#     NGINX_SYMLINK_1=/some/dir:/some/other/dir
#     NGINX_SYMLINK_2=/some/dir2:/some/other/dir2
#
# Symlinks will be created from
#
#    /some/dir to /some/other/dir
#    /some/dir2 to /some/other/dir2
#
function auto_symlink {
  if [ -z "${1}" ]; then
    prefix="SYMLINK"
  else
    prefix="${1}_SYMLINK"
  fi

  ln="${2:ln}"

  # if a "default link is given, give it a name under the prefix"
  if [ -n "${!prefix}" ]; then
    export "${prefix}__DEFAULT__"="${!prefix}"
  fi

  for var in $(compgen -v); do
    if [[ "${var}" =~ ^${prefix}_.*$ ]]; then
      link="${!var}"
      if [ -n "${link}" ]; then
        from="${link%%:*}"
        to="${link#*:}"
        if [ -z "${from}" ] || [ -z "${to}" ]; then
          echo "A link must be in the form <from>:<to>"
          exit 1
        else
          "${ln}" -f -s -T "${from}" "${to}"
        fi
      fi
    fi
  done
}
