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
#     NGINX_SYMLINK_3=/some/dir3 => /some/other/dir3
#     NGINX_SYMLINK_4=/some/somthing -> /some/other/dir4/
#
# Symlinks will be created from
#
#    /some/dir to /some/other/dir
#    /some/dir2 to /some/other/dir2
#    /some/dir3 to /some/other/dir3 (because the fat arrow was used above, the destionation is removed before linking)
#    /some/dir3 to /some/other/dir4/something (Creates `something` inside the dir4 because dir4 ended in a slash above )
#
# If the link is created with a "fat arrow" (=>) the destination is removed first
# with `rm -rf`
#
# After processing the environment variables, they are unset to avoid re-processing
# if auto_symlink is run again
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
      # Replace the single colon with a skinny arrow
      link="$(echo "${link}" | "${sed}" -E -e 's/:(\s*\/)/->\1/')"

      if [[ "${link}" =~ ^(.*)([=-]\>)(.*)$ ]]; then
        from="${BASH_REMATCH[1]}"
        to="${BASH_REMATCH[3]}"
        arrow="${BASH_REMATCH[2]}"

        from="$(trim "${from}")"
        to="$(trim "${to}")"
        arrow="$(trim "${arrow}")"

        # Unset the link so it doesn't get processed more than once
        unset -v "${var}"

        if [ -z "${from}" ] || [ -z "${to}" ]; then
          echo "A link must be in the form \"<from> -> <to>\" or \"<from> => <to>\""
          exit 1
        else
          # if the link is the same, don't bother linking (this allows multiple runs
          # with the same prefix)
          if [ "$(readlink "${to}")" = "${from}" ]; then
            return
          fi

          if [ "${arrow}" = "=>" ]; then
            if [ -d "${to}" ]; then
              rm -r "${to}"
            else
              rm "${to}"
            fi
          fi

          # If the target exists already, and is not a symlink, potentially raise an error
          if [ -e "${to}" ] && [ ! -L "${to}"  ]; then
            if [ -d "${to}" ] && [[ "${to}" =~ /$ ]]; then
              # The target is a directory and ends in a slash so make the link INSIDE
              # the directory
              : noop
            else
              echo "The destination (${to}) already exists, remove it or use the
 fat arrow (=>) or double colons (::) to automatically remove it when linked" >&2
              exit 1
            fi
          fi

          # If we are here that means that the target doesn't exist, is a symlink, or
          # the target ends in a slash and is a directory, in which case we will create a link
          # inside of the directory.
          if [[ "${to}" =~ /$ ]] && ([ -d "${to}" ] || [ -d "$(readlink "${to}")" ]); then
            "${ln}" -s "${from}" "${to}"
          else
            # Create the link, overwriting the target if it exists and is a symlink (-f -n)
            "${ln}" -f -s -n "${from}" "${to}"
          fi
        fi
      fi
    fi
  done
}
