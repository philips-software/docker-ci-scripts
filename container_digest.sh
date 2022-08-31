#!/bin/bash

set -e

# shellcheck disable=SC2153
docker_organization=$DOCKER_ORGANIZATION

if [ -z "$REGISTRY_URL" ]; then
  if [ -z "$docker_organization" ]; then
    echo "::error::No DOCKER_ORGANIZATION set. This is mandatory when using docker.io"
    exit 1
  fi
  REGISTRY_URL="docker.io"
  registry_url_prefix="$REGISTRY_URL/$docker_organization"
  echo "Docker organization: $docker_organization"
else
  registry_url_prefix="$REGISTRY_URL"
fi

echo "registry_url_prefix: $registry_url_prefix"

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

if [ -z "$REGISTRY_TOKEN" ]; then
  echo "::error::No REGISTRY_TOKEN set. Please provide"
  exit 1
fi

if [ -z "$REGISTRY_USERNAME" ]; then
  echo "::error::No REGISTRY_USERNAME set. Please provide"
  exit 1
fi

echo "Login to docker"
echo "--------------------------------------------------------------------------------------------"
echo "$REGISTRY_TOKEN" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin

docker pull "$registry_url_prefix"/"$imagename":"$basetag"

echo "Getting digest for $registry_url_prefix/$imagename:$basetag"
containerdigest=$(docker inspect "$registry_url_prefix"/"$imagename":"$basetag" --format '{{ index .RepoDigests 0 }}' | cut -d '@' -f 2)
echo "found: ${containerdigest}"
echo "::set-output name=container-digest::${containerdigest}"

echo "--------------------------------------------------------------------------------------------"

echo "Getting tags"
containertags=$(docker inspect "$registry_url_prefix"/"$imagename":"$basetag" --format '{{ join .RepoTags "\n" }}' | sed 's/.*://' | paste -s -d ',' -)
echo "found: ${containertags}"
echo "::set-output name=container-tags::${containertags}"

echo "============================================================================================"
echo "Finished getting docker digest and tags"
echo "============================================================================================"

echo '## Secure Software Supply Chain :rocket:' >> "$GITHUB_STEP_SUMMARY"
if [ -n "${SIGN}" ]
then
  echo '### Sign image' >> "$GITHUB_STEP_SUMMARY"
  echo "Signing image"

  COSIGN_KEY=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
  COSIGN_PUB=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1

  # COSGIN_PASSWORD should be passed as environment variable
  echo "${COSIGN_PRIVATE_KEY}" > "$COSIGN_KEY"
  echo "${COSIGN_PUBLIC_KEY}" > "$COSIGN_PUB"

  echo "Sign image"
  cosign sign --key "$COSIGN_KEY" "$registry_url_prefix"/"$imagename"@"${containerdigest}"

  echo "Verify signing"
  cosign verify --key "$COSIGN_PUB" "$registry_url_prefix"/"$imagename"@"${containerdigest}" 

  {
    echo 'Image is signed. You can verify it with the following command:'
    echo '```bash'
    echo "cosign verify --key cosign.pub $registry_url_prefix/$imagename@${containerdigest}"
    echo '```'
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ -n "${SLSA_PROVENANCE}" ]
then
  echo "### SLSA Provenance" >> "$GITHUB_STEP_SUMMARY"
  echo "Running SLSA Provenance"

  encoded_github="$(echo "$GITHUB_CONTEXT" | base64 -w 0)"
  encoded_runner="$(echo "$RUNNER_CONTEXT" | base64 -w 0)"

  slsa-provenance generate container \
    --github-context "$encoded_github" \
    --runner-context "$encoded_runner" \
    --repository "$registry_url_prefix"/"$imagename" \
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
    cosign attest --predicate provenance-predicate.json --key "$COSIGN_KEY" --type slsaprovenance "$registry_url_prefix"/"$imagename"@"${containerdigest}"

    {
      echo "SLSA Provenance file is attested. You can verify it with the following command."
      echo '```bash'
      echo "cosign verify-attestation --key cosign.pub $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType==\"https://slsa.dev/provenance/v0.2\" ) | .'"
      echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
  fi
fi

if [ -n "${SBOM}" ]
then
  echo "### SBOM" >> "$GITHUB_STEP_SUMMARY"
  echo "Using Syft to generate SBOM"

  syft packages "$registry_url_prefix"/"$imagename"@"${containerdigest}" -o spdx-json=sbom-spdx-formatted.json

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
    cosign attest --predicate sbom-spdx.json --type spdx --key "$COSIGN_KEY" "$registry_url_prefix"/"$imagename"@"${containerdigest}"

    echo "Done attesting the SBOM"

    {
      echo "SBOM file is attested. You can verify it with the following command."
      echo '```bash'
      echo "cosign verify-attestation --key cosign.pub $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType==\"https://spdx.dev/Document\" ) | .predicate.Data | fromjson | .'" 
      echo '```'
    } >> "$GITHUB_STEP_SUMMARY"

  fi
fi

if [ -n "${SIGN}" ]
  then
  echo "Cleanup"
  rm "$COSIGN_KEY"
  rm "$COSIGN_PUB"
fi
