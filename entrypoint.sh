#!/bin/sh -l

echo ""
echo "=========================================================================================================="
echo "⚠️  DEPRECATION WARNING: This action is deprecated and will no longer receive updates."
echo "=========================================================================================================="
echo ""
echo "Please migrate to the official Docker GitHub Actions for better support and features:"
echo ""
echo "  1. docker/setup-buildx-action   - https://github.com/docker/setup-buildx-action"
echo "  2. docker/metadata-action        - https://github.com/docker/metadata-action"
echo "  3. docker/build-push-action      - https://github.com/docker/build-push-action"
echo ""
echo "For SBOM and provenance attestations, use the built-in support in docker/build-push-action:"
echo "  - Documentation: https://docs.docker.com/build/ci/github-actions/attestations/"
echo ""
echo "See the README for a complete migration example:"
echo "  - https://github.com/philips-software/docker-ci-scripts#readme"
echo ""
echo "=========================================================================================================="
echo ""

# Write deprecation notice to GitHub Step Summary
{
  echo "## ⚠️ DEPRECATION NOTICE"
  echo ""
  echo "**This action is deprecated and will no longer receive updates.**"
  echo ""
  echo "Please migrate to the official Docker GitHub Actions:"
  echo ""
  echo "### Recommended Migration"
  echo ""
  echo "1. **[docker/setup-buildx-action](https://github.com/docker/setup-buildx-action)** - Set up Docker Buildx"
  echo "2. **[docker/metadata-action](https://github.com/docker/metadata-action)** - Generate image metadata and tags"
  echo "3. **[docker/build-push-action](https://github.com/docker/build-push-action)** - Build and push images"
  echo ""
  echo "### Attestations & Signing"
  echo ""
  echo "For SBOM and provenance attestations, use the built-in support in \`docker/build-push-action\`:"
  echo ""
  echo "- 📖 [Docker Build Attestations Documentation](https://docs.docker.com/build/ci/github-actions/attestations/)"
  echo ""
  echo "### Migration Example"
  echo ""
  echo "See the [README](https://github.com/philips-software/docker-ci-scripts#readme) for a complete migration example."
  echo ""
  echo "---"
  echo ""
} >> "$GITHUB_STEP_SUMMARY"

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
