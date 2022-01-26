#!/bin/sh -l

if [ -n "${SLSA_PROVENANCE}" ]
then
  echo "+ SLSA Provenance ---------"
  echo "| Installing slsa provenance"
  . $GITHUB_ACTION_PATH/scripts/install_slsa_provenance.sh
  echo "| Show slsa provenance version"
  slsa-provenance version
  echo "| Finished installing slsa-provenance"
  echo "- SLSA Provenance ---------"
fi

if [ -n "${SIGN}" ]
then
  echo "+ Cosign ------------------"
  echo "| Installing cosign"
  $GITHUB_ACTION_PATH/scripts/install_cosign.sh
  export PATH=${HOME}/.cosign:$PATH
  echo "| Show cosign version"
  cosign version
  echo "| Finished installing cosign"
  echo "- Cosign ------------------"
fi

echo "dockerfile     : $1"
echo "image name     : $2"
echo "tags           : $3"
echo "push branches  : $4"
echo "base dir       : $5"
echo "push branch    : $6"

if [ -z "$6" ]
  then
    export PUSH_BRANCHES="$4"
  else
    echo "DEPRECATION WARNING: push-branch will be replaced by push-branches"
    export PUSH_BRANCHES="$6"
fi

"${FOREST_DIR}"/docker_build_and_push.sh "$1" "$2" "$5" "$3"
