#!/bin/sh -l

# Code from https://github.com/peter-evans/dockerhub-description with some small adjustments.
# Since the dockerfile takes in username and password, we want full control so the credentials are not shared.

set -e

# Set the default path to README.md
README_FILEPATH="/github/workspace/${README_FILEPATH:="README.md"}"

# Acquire a token for the Docker Hub API
echo "Acquiring token"
LOGIN_PAYLOAD="{\"username\": \"${REGISTRY_USERNAME}\", \"password\": \"${REGISTRY_TOKEN}\"}"
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d "${LOGIN_PAYLOAD}" https://hub.docker.com/v2/users/login/ | jq -r .token)

# Send a PATCH request to update the description of the repository
echo "Sending PATCH request"
REPO_URL="https://hub.docker.com/v2/repositories/${DOCKER_REPOSITORY}/"
# shellcheck disable=SC1083
RESPONSE_CODE=$(curl -s --write-out %{response_code} --output /dev/null -H "Authorization: JWT ${TOKEN}" -X PATCH --data-urlencode full_description@${README_FILEPATH} "${REPO_URL}")
echo "Received response code: $RESPONSE_CODE"

if [ "$RESPONSE_CODE" -eq 200 ]; then
  echo "Readme updated successfully" >> "$GITHUB_STEP_SUMMARY"
else
  echo "Error updating readme"
  exit 1
fi
