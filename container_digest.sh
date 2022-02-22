#!/bin/bash

set -e

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$DOCKER_REGISTRY" ]; then
  if [ -z "$docker_organization" ]; then
    echo "::error::No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
    exit 1
  fi
  DOCKER_REGISTRY="docker.io"
  docker_registry_prefix="$DOCKER_REGISTRY/$docker_organization"
  echo "Docker organization: $docker_organization"
else
  docker_registry_prefix="$DOCKER_REGISTRY"
fi

echo "docker_registry_prefix: $docker_registry_prefix"

# builddir=$1
shift
imagename=$1
shift
# basedir=$1 // Is not used, so why bother to capture this in a variable.
shift
alltags=$*
IFS=' '
read -ra tags <<<"$alltags"
basetag=${tags[0]}

if [ -z "$DOCKER_PASSWORD" ]; then
  echo "::error::No DOCKER_PASSWORD set. Please provide"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "::error::No DOCKER_USERNAME set. Please provide"
  exit 1
fi

echo "Login to docker"
echo "--------------------------------------------------------------------------------------------"
echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin

docker pull "$docker_registry_prefix"/"$imagename":"$basetag"

echo "Getting digest for $docker_registry_prefix/$imagename:$basetag"
containerdigest=$(docker inspect "$docker_registry_prefix"/"$imagename":"$basetag" --format '{{ index .RepoDigests 0 }}' | cut -d '@' -f 2)
echo "found: ${containerdigest}"
echo "::set-output name=container-digest::${containerdigest}"

echo "--------------------------------------------------------------------------------------------"

echo "Getting tags"
containertags=$(docker inspect "$docker_registry_prefix"/"$imagename":"$basetag" --format '{{ join .RepoTags "\n" }}' | sed 's/.*://' | paste -s -d ',' -)
echo "found: ${containertags}"
echo "::set-output name=container-tags::${containertags}"

echo "============================================================================================"
echo "Finished getting docker digest and tags"
echo "============================================================================================"

if [ -n "${SIGN}" ]
then
  echo "Signing image"

  COSIGN_KEY=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
  COSIGN_PUB=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1

  # COSGIN_PASSWORD should be passed as environment variable
  echo "${COSIGN_PRIVATE_KEY}" > "$COSIGN_KEY"
  echo "${COSIGN_PUBLIC_KEY}" > "$COSIGN_PUB"

  echo "Sign image"
  cosign sign --key "$COSIGN_KEY" "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

  echo "Verify signing"
  cosign verify --key "$COSIGN_PUB" "$docker_registry_prefix"/"$imagename"@"${containerdigest}" 
 
  echo "::notice::Image is signed. You can verify it with the following command."
  echo "::notice::cosign verify --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}""
fi

if [ -n "${SLSA_PROVENANCE}" ]
then
  echo "Running SLSA Provenance"

  encoded_github="$(echo "$GITHUB_CONTEXT" | base64 -w 0)"
  encoded_runner="$(echo "$RUNNER_CONTEXT" | base64 -w 0)"

  slsa-provenance generate container \
    --github-context "$encoded_github" \
    --runner-context "$encoded_runner" \
    --repository "$docker_registry_prefix"/"$imagename" \
    --digest "${containerdigest}" \
    --tags "${containertags}"

  echo "-------------------------------------------------------------------------------------------"
  echo " provenance.json "
  echo "-------------------------------------------------------------------------------------------"
  echo "::set-output name=slsa-provenance-file::provenance.json"

  echo "============================================================================================"
  echo "Finished getting SLSA Provenance"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SLSA Provenance with Cosign"

    echo "Get predicate"
    jq .predicate < provenance.json > provenance-predicate.json

    echo "Attest predicate"
    cosign attest --predicate provenance-predicate.json --key "$COSIGN_KEY" --type slsaprovenance "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "::notice::SLSA Provenance file is attested. You can verify it with the following command."
    echo "::notice::cosign verify-attestation --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}" | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType==\"https://slsa.dev/provenance/v0.2\" ) | .'"
  fi
fi

if [ -n "${SBOM}" ]
then
  echo "Using Syft to generate SBOM"

  syft packages "$docker_registry_prefix"/"$imagename"@"${containerdigest}" -o spdx-json=sbom-spdx-formatted.json

  echo "Remove formatting"
  jq -c . sbom-spdx-formatted.json > sbom-spdx.json

  echo "::set-output name=sbom-file::sbom-spdx.json"

  echo "============================================================================================"
  echo "Finished getting SBOM"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SBOM  with Cosign"

    echo "Attest SBOM"
    cosign attest --predicate sbom-spdx.json --type spdx --key "$COSIGN_KEY" "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "Done attesting the SBOM"

    echo "::notice::SBOM file is attested. You can verify it with the following command."
    echo "::notice::cosign verify-attestation --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}" | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType==\"https://spdx.dev/Document\" ) | .predicate.Data | fromjson | .'" 
  fi
fi

if [ -n "${SIGN}" ]
  then
  echo "Cleanup"
  rm "$COSIGN_KEY"
  rm "$COSIGN_PUB"
fi
