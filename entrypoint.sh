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

 export PUSH_BRANCHES="$4"

if [ -n "${DOCKER_USERNAME}" ]; then
  echo "ERROR: DOCKER_USERNAME is replaced by REGISTRY_USERNAME. Please update scripts."
  echo "ERROR: DOCKER_USERNAME is replaced by REGISTRY_USERNAME. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

if [ -n "${DOCKER_PASSWORD}" ]; then
  echo "ERROR: DOCKER_PASSWORD is replaced by REGISTRY_TOKEN. Please update scripts."
  echo "ERROR: DOCKER_PASSWORD is replaced by REGISTRY_TOKEN. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

if [ -n "${DOCKER_REGISTRY}" ]; then
  echo "ERROR: DOCKER_REGISTRY is replaced by REGISTRY_URL. Please update scripts."
  echo "ERROR: DOCKER_REGISTRY is replaced by REGISTRY_URL. Please update scripts." >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

"${FOREST_DIR}"/docker_build_and_push.sh "$1" "$2" "$5" "$3"
