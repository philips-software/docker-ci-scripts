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

if [ -n "${SBOM}" ]
then
  echo "+ SBOM -------------------"
  echo "| Installing Syft"
  . $GITHUB_ACTION_PATH/scripts/install_syft.sh
  echo "| Show Syft version"
  syft version
  echo "| Finished installing Syft"
  echo "- Syft -------------------"
fi

if [ "${PUSH_ON_GIT_TAG}" = true ]
then
  echo "+ PUSH_ON_GIT_TAG -------------------"
  echo "| Push on git tag flag is set to true."
  echo "- PUSH_ON_GIT_TAG -------------------"
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
    echo "DEPRECATION WARNING: push-branch will be replaced by push-branches. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
    export PUSH_BRANCHES="$6"
fi

if [ -n "${DOCKER_USERNAME}" ]; then
  echo "DEPRECATION WARNING: DOCKER_USERNAME will be replaced by REGISTRY_USERNAME in the next release. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  export REGISTRY_USERNAME="${DOCKER_USERNAME}"
fi

if [ -n "${DOCKER_PASSWORD}" ]; then
  echo "DEPRECATION WARNING: DOCKER_PASSWORD will be replaced by REGISTRY_TOKEN in the next release. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  export REGISTRY_TOKEN="${DOCKER_PASSWORD}"
fi

if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "DEPRECATION WARNING: DOCKER_REGISTRY will be replaced by REGISTRY_URL in the next release. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  export REGISTRY_URL="${DOCKER_REGISTRY}"
fi

"${FOREST_DIR}"/docker_build_and_push.sh "$1" "$2" "$5" "$3"
