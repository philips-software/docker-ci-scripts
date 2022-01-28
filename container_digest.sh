#!/bin/bash

set -e

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$DOCKER_REGISTRY" ]; then
  if [ -z "$docker_organization" ]; then
    echo "  No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
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
  echo "  No DOCKER_PASSWORD set. Please provide"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "  No DOCKER_USERNAME set. Please provide"
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

  # COSGIN_PASSWORD should be passed as environment variable
  echo "${COSIGN_PRIVATE_KEY}" > cosign.key

  echo "Sign image"
  cosign sign --key cosign.key "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

  echo "Verify signing"
  cosign verify --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}" 

  echo "Cleanup"
  rm cosign.key
  rm cosign.pub
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

  cat provenance.json
  echo

  echo "::set-output name=slsa-provenance-file::provenance.json"

  echo "============================================================================================"
  echo "Finished getting SLSA Provenance"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SLSA Provenance with Cosign"
    echo "Get predicate"
    echo "${COSIGN_PRIVATE_KEY}" > cosign.key
    jq .predicate < provenance.json > provenance-predicate.json

    echo "Attest predicate"
    # COSGIN_PASSWORD should be passed as environment variable
    echo "${COSIGN_PRIVATE_KEY}" > cosign.key
    cosign attest --predicate provenance-predicate.json --key cosign.key --type slsaprovenance "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "Verify predicate"
    echo "${COSIGN_PUBLIC_KEY}" > cosign.pub
    cosign verify-attestation --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "Cleanup"
    rm cosign.key
    rm cosign.pub
  fi
fi

if [ -n "${SBOM}" ]
then
  echo "Using TERN to generate SBOM"

  docker run --rm philipssoftware/tern:2.9.1 report -f json -i "$docker_registry_prefix"/"$imagename"@"${containerdigest}" > sbom-spdx.json

  echo "::set-output name=sbom-file::sbom-spdx.json"

  echo "============================================================================================"
  echo "Finished getting SBOM"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SBOM  with Cosign"
    echo "${COSIGN_PRIVATE_KEY}" > cosign.key

    echo "Attest SBOM"
    # COSGIN_PASSWORD should be passed as environment variable
    echo "${COSIGN_PRIVATE_KEY}" > cosign.key
    cosign attest --predicate sbom-spdx.json --type spdx --key cosign.key "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "Verify SBOM"
    echo "${COSIGN_PUBLIC_KEY}" > cosign.pub
    cosign verify-attestation --key cosign.pub "$docker_registry_prefix"/"$imagename"@"${containerdigest}"

    echo "Cleanup"
    rm cosign.key
    rm cosign.pub
  fi
fi


