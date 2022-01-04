FROM docker:20.10.12-git

RUN apk update && apk add \
    bash \
    jq \
    curl \
    wget \
    git

LABEL "name"="docker-build"
LABEL "maintainer"="Jeroen Knoops <jeroen.knoops@philips.com>"
LABEL "version"="0.0.0"

LABEL "com.github.actions.name"="Docker Build and Push for Github Action"
LABEL "com.github.actions.description"="Builds docker images and publish master"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="gray-dark"

ENV FOREST_DIR=/forest
RUN mkdir -p ${FOREST_DIR}

COPY LICENSE.md README.md ${FOREST_DIR}/
COPY docker_build.sh docker_push.sh docker_build_and_push.sh update_readme.sh container_digest.sh ${FOREST_DIR}/
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
