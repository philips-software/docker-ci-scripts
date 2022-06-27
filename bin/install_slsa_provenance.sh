#!/bin/bash

SLSA_PROVENANCE_VERSION=0.8.0
INSTALL_DIR=$HOME/.slsa_provenance

function install_slsa_provenance {
    case "$(uname -s)" in
        Linux*)
            machine=linux
            shasum=sha256sum
            ;;
        Darwin*)
            machine=macOS
            shasum=shasum
            ;;
    esac

    curl -sSLO https://github.com/philips-labs/slsa-provenance-action/releases/download/v${SLSA_PROVENANCE_VERSION}/slsa-provenance_${SLSA_PROVENANCE_VERSION}_${machine}_amd64.tar.gz
    curl -sSLO https://github.com/philips-labs/slsa-provenance-action/releases/download/v${SLSA_PROVENANCE_VERSION}/checksums.txt
    < checksums.txt grep -E "slsa-provenance_${SLSA_PROVENANCE_VERSION}_${machine}_amd64.tar.gz$" | $shasum -c -

    # shellcheck disable=SC2181
    if [ $? != 0 ] ; then
        echo Checksum does not match.
        exit 1
    fi

    mkdir -p "${INSTALL_DIR}"
    tar -xf slsa-provenance_${SLSA_PROVENANCE_VERSION}_${machine}_amd64.tar.gz -C "${INSTALL_DIR}"
    chmod +x "${INSTALL_DIR}"/slsa-provenance
    rm -f slsa-provenance_${SLSA_PROVENANCE_VERSION}_${machine}_amd64.tar.gz checksums.txt
}

install_slsa_provenance
export PATH=${INSTALL_DIR}:$PATH
