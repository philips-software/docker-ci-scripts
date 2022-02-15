#!/bin/bash

SYFT_VERSION=0.37.10
INSTALL_DIR=$HOME/.syft

function install_syft {
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

    curl -sSLO https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_${machine}_amd64.tar.gz
    curl -sSLO https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_checksums.txt
    < syft_${SYFT_VERSION}_checksums.txt grep syft_${SYFT_VERSION}_${machine}_amd64.tar.gz | $shasum -c -

    # shellcheck disable=SC2181
    if [ $? != 0 ] ; then
        echo Checksum does not match.
        exit 1
    fi

    mkdir -p "${INSTALL_DIR}"
    tar -xf syft_${SYFT_VERSION}_${machine}_amd64.tar.gz -C "${INSTALL_DIR}"
    chmod +x "${INSTALL_DIR}"/syft
    rm -f syft_${SYFT_VERSION}_${machine}_amd64.tar.gz syft_${SYFT_VERSION}_checksums.txt
}

install_syft
export PATH=${INSTALL_DIR}:$PATH
