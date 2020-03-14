FROM alpine:3.11

RUN apk update && apk add \
    bash \
    git

LABEL "name"="docker-build"
LABEL "maintainer"="Jeroen Knoops <jeroen.knoops@philips.com>"
LABEL "version"="0.0.0"

LABEL "com.github.actions.name"="Docker Build and Push for Github Action"
LABEL "com.github.actions.description"="Builds docker images and publish master"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="gray-dark"

COPY LICENSE.md README.md /

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
