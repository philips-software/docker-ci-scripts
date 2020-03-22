FROM docker:19.03.8-git

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

COPY LICENSE.md README.md /

COPY docker_build.sh docker_push.sh docker_build_and_push.sh update_readme.sh /

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
