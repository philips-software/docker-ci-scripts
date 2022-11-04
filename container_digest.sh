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
echo "container-digest=${containerdigest}" >> "$GITHUB_OUTPUT"

echo "--------------------------------------------------------------------------------------------"

echo "Getting tags"
containertags=$(docker inspect "$registry_url_prefix"/"$imagename":"$basetag" --format '{{ join .RepoTags "\n" }}' | sed 's/.*://' | paste -s -d ',' -)
echo "found: ${containertags}"
echo "container-tags=${containertags}" >> "$GITHUB_OUTPUT"

echo "============================================================================================"
echo "Finished getting docker digest and tags"
echo "============================================================================================"

echo '## Secure Software Supply Chain :rocket:' >> "$GITHUB_STEP_SUMMARY"
if [ -n "${SIGN}" ]
then
  echo '### Sign image' >> "$GITHUB_STEP_SUMMARY"
  echo "Signing image"

  if [ -n "${KEYLESS}" ]
  then
    echo 'Keyless signing'
    COSIGN_KEY_ARGUMENT=""
    COSIGN_PUB_ARGUMENT=""
    export COSIGN_EXPERIMENTAL=1
  else
    echo 'Signing using COSIGN keys'
    COSIGN_KEY=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
    COSIGN_PUB=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1

    # COSGIN_PASSWORD should be passed as environment variable
    echo "${COSIGN_PRIVATE_KEY}" > "$COSIGN_KEY"
    echo "${COSIGN_PUBLIC_KEY}" > "$COSIGN_PUB"

    COSIGN_KEY_ARGUMENT="--key $COSIGN_KEY"
    COSIGN_PUB_ARGUMENT="--key $COSIGN_PUB"
  fi
  echo "Sign image"

  set -x 
  TEMP_OUTPUT=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
  # shellcheck disable=SC2086
  cosign sign ${COSIGN_KEY_ARGUMENT} "$registry_url_prefix"/"$imagename"@"${containerdigest}" 2> >(tee -a $TEMP_OUTPUT >&2)
  set +x 
  echo "-==================-"
  cat $TEMP_OUTPUT
  echo "-==================-"
  tlog_id=$(grep "tlog entry created with index"  "$TEMP_OUTPUT" | grep -o '[0-9]\+')
  echo "tlog_id: $tlog_id"
  rm "$TEMP_OUTPUT" 

  echo "Verify signing"
  # shellcheck disable=SC2086
  cosign verify ${COSIGN_PUB_ARGUMENT} "$registry_url_prefix"/"$imagename"@"${containerdigest}"

  {
    echo 'Image is signed. You can verify it with the following command:'
    echo '```bash'
    if [ -n "${KEYLESS}" ]
    then
      echo "export COSIGN_EXPERIMENTAL=1"
      echo "cosign verify $registry_url_prefix/$imagename@${containerdigest}"
    else
      echo "cosign verify --key cosign.pub $registry_url_prefix/$imagename@${containerdigest}"
    fi
    echo '```'
    if [ -n "${KEYLESS}" ]
    then
      echo "Public Rekore tlog-url: <https://rekor.tlog.dev/?logIndex=$tlog_id>"
    fi
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
  echo "slsa-provenance-file=provenance.json" >> "$GITHUB_OUTPUT"

  echo "============================================================================================"
  echo "Finished getting SLSA Provenance"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SLSA Provenance with Cosign"

    echo "Get predicate"
    jq .predicate < provenance.json > provenance-predicate.json

    echo "Attest predicate"

    TEMP_OUTPUT=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
    # shellcheck disable=SC2086
    cosign attest --predicate provenance-predicate.json ${COSIGN_KEY_ARGUMENT} --type slsaprovenance "$registry_url_prefix"/"$imagename"@"${containerdigest}" 2> >(tee -a $TEMP_OUTPUT >&2)
    tlog_id=$(grep "tlog entry created with index"  "$TEMP_OUTPUT" | grep -o '[0-9]\+')
    echo "tlog_id: $tlog_id"
    rm "$TEMP_OUTPUT" 

    {
      echo "SLSA Provenance file is attested. You can verify it with the following command."
      echo '```bash'
      if [ -n "${KEYLESS}" ]
      then
        echo "export COSIGN_EXPERIMENTAL=1"
        echo "cosign verify-attestation --type slsaprovenance $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType==\"https://slsa.dev/provenance/v0.2\" ) | .'"
        # TODO: Add tlog
      else
        echo "cosign verify-attestation --key cosign.pub --type slsaprovenance $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select(.predicateType==\"https://slsa.dev/provenance/v0.2\" ) | .'"
      fi
      echo '```'
      if [ -n "${KEYLESS}" ]
      then
        echo "Public Rekore tlog-url: <https://rekor.tlog.dev/?logIndex=$tlog_id>"
      fi
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

  echo "sbom-file=sbom-spdx.json" >> "$GITHUB_OUTPUT"

  echo "============================================================================================"
  echo "Finished getting SBOM"
  echo "============================================================================================"

  if [ -n "${SIGN}" ]
  then
    echo "Attaching SBOM  with Cosign"

    echo "Attest SBOM"

    TEMP_OUTPUT=$(mktemp /tmp/cosign.XXXXXXXXXX) || exit 1
    # shellcheck disable=SC2086
    cosign attest --predicate sbom-spdx.json --type spdx ${COSIGN_KEY_ARGUMENT} "$registry_url_prefix"/"$imagename"@"${containerdigest}" 2> >(tee -a $TEMP_OUTPUT >&2)
    tlog_id=$(grep "tlog entry created with index"  "$TEMP_OUTPUT" | grep -o '[0-9]\+')
    echo "tlog_id: $tlog_id"
    rm "$TEMP_OUTPUT" 

    echo "Done attesting the SBOM"

    {
      echo "SBOM file is attested. You can verify it with the following command."
      echo '```bash'
      if [ -n "${KEYLESS}" ]
      then
        echo "export COSIGN_EXPERIMENTAL=1"
        echo "cosign verify-attestation --type spdx $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType==\"https://spdx.dev/Document\" ) | .predicate.Data | fromjson | .'"
        # TODO: Add tlog
      else
        echo "cosign verify-attestation --key cosign.pub --type spdx $registry_url_prefix/$imagename@${containerdigest} | jq '.payload |= @base64d | .payload | fromjson | select( .predicateType==\"https://spdx.dev/Document\" ) | .predicate.Data | fromjson | .'"
      fi
      echo '```'
      if [ -n "${KEYLESS}" ]
      then
        echo "Public Rekore tlog-url: <https://rekor.tlog.dev/?logIndex=$tlog_id>"
      fi
    } >> "$GITHUB_STEP_SUMMARY"

  fi
fi

if [ -n "${SIGN}" ]
then
  if [ -n "${KEYLESS}" ]
  then
    echo "Keyless so nothing to cleanup"
  else
    echo "Cleanup"
    rm "$COSIGN_KEY"
    rm "$COSIGN_PUB"
  fi
fi

