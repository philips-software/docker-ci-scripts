FROM docker:23.0.5-git

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
LABEL "com.github.actions.description"="Builds docker images and publish them on request"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="gray-dark"

ENV FOREST_DIR=/forest
RUN mkdir -p ${FOREST_DIR}

COPY LICENSE.md README.md ${FOREST_DIR}/
COPY docker_build.sh docker_push.sh docker_build_and_push.sh update_readme.sh container_digest.sh ${FOREST_DIR}/
COPY entrypoint.sh /

RUN mkdir -p /scripts
ADD bin/install_cosign.sh /scripts
RUN chmod +x /scripts/install_cosign.sh

ADD bin/install_slsa_provenance.sh /scripts
RUN chmod +x /scripts/install_slsa_provenance.sh

ADD bin/install_syft.sh /scripts
RUN chmod +x /scripts/install_syft.sh

ENTRYPOINT ["/entrypoint.sh"]
