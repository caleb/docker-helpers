#!/usr/bin/env bats

function setup {
  mkdir -p "${BATS_TMPDIR}/auto_link"
  __TMPDIR="${BATS_TMPDIR}/auto_link"

  # Make sure we are using gnu ln because we need the -T flag
  if [ -n "$(which gln)" ]; then
    LN="gln"
  else
    LN="ln"
  fi
}

function teardown {
  rm -rf "${__TMPDIR}"
}

@test "Creates symlinks from the default environment variable (SYMLINK)" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"

  SYMLINK="${__TMPDIR}/source -> ${__TMPDIR}/dest"

  auto_symlink "" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
}

@test "Creates symlinks from multiple default-prefixed variables (SYMLINK_*)" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"
  mkdir -p "${__TMPDIR}/source3"

  SYMLINK_0="${__TMPDIR}/source -> ${__TMPDIR}/dest"
  SYMLINK_1="${__TMPDIR}/source2 -> ${__TMPDIR}/dest2"
  SYMLINK_2="${__TMPDIR}/source3 -> ${__TMPDIR}/dest3"

  auto_symlink "" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
  [ -L "${__TMPDIR}/dest2" ]
  [ -L "${__TMPDIR}/dest3" ]
}

@test "Creates symlinks from a custom prefix" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"
  mkdir -p "${__TMPDIR}/source3"

  MY_SYMLINK_0="${__TMPDIR}/source -> ${__TMPDIR}/dest"
  MY_SYMLINK_1="${__TMPDIR}/source2 -> ${__TMPDIR}/dest2"
  MY_SYMLINK_2="${__TMPDIR}/source3 -> ${__TMPDIR}/dest3"

  auto_symlink "MY" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
  [ -L "${__TMPDIR}/dest2" ]
  [ -L "${__TMPDIR}/dest3" ]
}

@test "Handles no spaces arround the arrow" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"
  mkdir -p "${__TMPDIR}/source3"

  MY_SYMLINK_0="${__TMPDIR}/source->${__TMPDIR}/dest"
  MY_SYMLINK_1="${__TMPDIR}/source2->${__TMPDIR}/dest2"
  MY_SYMLINK_2="${__TMPDIR}/source3->${__TMPDIR}/dest3"

  auto_symlink "MY" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
  [ -L "${__TMPDIR}/dest2" ]
  [ -L "${__TMPDIR}/dest3" ]
}

@test "Handles extra spaces arround the arrow" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"
  mkdir -p "${__TMPDIR}/source3"

  MY_SYMLINK_0="${__TMPDIR}/source   ->    ${__TMPDIR}/dest"
  MY_SYMLINK_1="${__TMPDIR}/source2   ->    ${__TMPDIR}/dest2"
  MY_SYMLINK_2="${__TMPDIR}/source3   ->    ${__TMPDIR}/dest3"

  auto_symlink "MY" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
  [ -L "${__TMPDIR}/dest2" ]
  [ -L "${__TMPDIR}/dest3" ]
}

@test "Errors out when a target exists already and the skinny arrow (->) is used" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/dest"

  MY_SYMLINK_0="${__TMPDIR}/source -> ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -ne 0 ]
}

@test "Errors out when a target exists already and the skinny arrow (:) is used" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/dest"

  MY_SYMLINK_0="${__TMPDIR}/source : ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -ne 0 ]
}

@test "Destroys the target if it exists when using the fat arrow" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/dest"

  MY_SYMLINK_0="${__TMPDIR}/source => ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
}

@test "Destroys the target if it exists when using the double colons" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/dest"

  MY_SYMLINK_0="${__TMPDIR}/source :: ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
}

@test "Colons work as separators too" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"

  MY_SYMLINK_0="${__TMPDIR}/source:${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
}

@test "Colons with extra spaces work" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
}

@test "If the destination ends in a slash, create the link inside the directory" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/dest"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest/"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest/source" ]
}

@test "Running twice with the same prefix is safe" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]

  run auto_symlink "MY" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
}

@test "Running twice with a common dest but different sources results in a link pointing to the last run link" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest"
  MY2_SYMLINK_0="${__TMPDIR}/source2  :  ${__TMPDIR}/dest"

  run auto_symlink "MY" "${LN}"
  run auto_symlink "MY2" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
  [ "$(readlink "${__TMPDIR}/dest")" = "${__TMPDIR}/source2" ]
}

@test "Running with a prefix more than once has no effect. (e.g. Running prefix ONE then TWO then ONE results in the links of TWO)" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"
  mkdir -p "${__TMPDIR}/source2"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest"
  MY2_SYMLINK_0="${__TMPDIR}/source2  :  ${__TMPDIR}/dest"

  auto_symlink "MY" "${LN}"
  auto_symlink "MY2" "${LN}"
  auto_symlink "MY" "${LN}"

  [ -L "${__TMPDIR}/dest" ]
  [ "$(readlink "${__TMPDIR}/dest")" = "${__TMPDIR}/source2" ]
}

@test "Allow the destination to end in a slash to create a link inside a directory even when that directory is a symlink" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${__TMPDIR}/source"

  MY_SYMLINK_0="${__TMPDIR}/source  :  ${__TMPDIR}/dest"
  MY2_SYMLINK_0="${__TMPDIR}/source2  :  ${__TMPDIR}/dest/"

  run auto_symlink "MY" "${LN}"
  run auto_symlink "MY2" "${LN}"

  [ "${status}" -eq 0 ]
  [ -L "${__TMPDIR}/dest" ]
  [ -L "${__TMPDIR}/dest/source2" ]
  [ "$(readlink "${__TMPDIR}/dest")" = "${__TMPDIR}/source" ]
  [ "$(readlink "${__TMPDIR}/dest/source2")" = "${__TMPDIR}/source2" ]
}
