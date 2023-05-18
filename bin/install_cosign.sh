#!/bin/bash

COSIGN_RELEASE=v1.13.1
INSTALL_DIR=$HOME/.cosign

RUNNER_OS=$(uname)
# RUNNER_ARCH=$(uname -m)
RUNNER_ARCH=X64

uname -a

#cosign install script
shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
  alias log_info="echo -e \"\033[1;32mINFO\033[0m:\""
  alias log_error="echo -e \"\033[1;31mERROR\033[0m:\""
else
  alias log_info="echo \"INFO:\""
  alias log_error="echo \"ERROR:\""
fi
set -e
shaprog() {
  case ${RUNNER_OS} in
    Linux)
      sha256sum $1 | cut -d' ' -f1
      ;;
    macOS)
      shasum -a256 $1 | cut -d' ' -f1
      ;;
    Windows)
      powershell -command "(Get-FileHash $1 -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()"
      ;;
    *)
      log_error "unsupported OS ${RUNNER_OS}}"
      exit 1
      ;;
  esac
}

bootstrap_version='v1.13.1'
bootstrap_linux_amd64_sha='a50651a67b42714d6f1a66eb6773bf214dacae321f04323c0885f6a433051f95'
bootstrap_linux_arm_sha='edc24d49459a73f54e78868a3540e1e54452ad2328c66e1eba8bcd78fcd349fc'
bootstrap_linux_arm64_sha='a7a79a52c7747e2c21554cad4600e6c7130c0429017dd258f9c558d957fa9090'
bootstrap_darwin_amd64_sha='1d164b8b1fcfef1e1870d809edbb9862afd5995cab63687a440b84cca5680ecf'
bootstrap_darwin_arm64_sha='02bef878916be048fd7dcf742105639f53706a59b5b03f4e4eaccc01d05bc7ab'
bootstrap_windows_amd64_sha='78a2774b68b995cc698944f6c235b1c93dcb6d57593a58a565ee7a56d64e4b85'
cosign_executable_name=cosign

trap "popd >/dev/null" EXIT
mkdir -p ${INSTALL_DIR}
pushd ${INSTALL_DIR} > /dev/null
case ${RUNNER_OS} in
  Linux)
    case ${RUNNER_ARCH} in
      X64)
        bootstrap_filename='cosign-linux-amd64'
        bootstrap_sha=${bootstrap_linux_amd64_sha}
        desired_cosign_filename='cosign-linux-amd64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_linux_amd64_0.6.0_linux_amd64'
          desired_cosign_v060_signature='cosign_linux_amd64_0.6.0_linux_amd64.sig'
        fi
        ;;

      ARM)
        bootstrap_filename='cosign-linux-arm'
        bootstrap_sha=${bootstrap_linux_arm_sha}
        desired_cosign_filename='cosign-linux-arm'
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          log_error "linux-arm build not available at v0.6.0"
          exit 1
        fi
        ;;

      ARM64)
        bootstrap_filename='cosign-linux-arm64'
        bootstrap_sha=${bootstrap_linux_arm64_sha}
        desired_cosign_filename='cosign-linux-amd64'
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          log_error "linux-arm64 build not available at v0.6.0"
          exit 1
        fi
        ;;

      *)
        log_error "unsupported architecture ${RUNNER_ARCH}"
        exit 1
        ;;
    esac
    ;;

  macOS)
    case ${RUNNER_ARCH} in
      X64)
        bootstrap_filename='cosign-darwin-amd64'
        bootstrap_sha=${bootstrap_darwin_amd64_sha}
        desired_cosign_filename='cosign-darwin-amd64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_darwin_amd64_0.6.0_darwin_amd64'
          desired_cosign_v060_signature='cosign_darwin_amd64_0.6.0_darwin_amd64.sig'
        fi
        ;;

      ARM64)
        bootstrap_filename='cosign-darwin-arm64'
        bootstrap_sha=${bootstrap_darwin_arm64_sha}
        desired_cosign_filename='cosign-darwin-arm64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_darwin_arm64_0.6.0_darwin_arm64'
          desired_cosign_v060_signature='cosign_darwin_arm64_0.6.0_darwin_arm64.sig'
        fi
        ;;

      *)
        log_error "unsupported architecture $arch"
        exit 1
        ;;
    esac
    ;;
  Windows)
    case ${RUNNER_ARCH} in
      X64)
        bootstrap_filename='cosign-windows-amd64.exe'
        bootstrap_sha=${bootstrap_windows_amd64_sha}
        desired_cosign_filename='cosign-windows-amd64.exe'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_windows_amd64_0.6.0_windows_amd64.exe'
          desired_cosign_v060_signature='cosign_windows_amd64_0.6.0_windows_amd64.exe.sig'
        fi
        ;;
      *)
        log_error "unsupported architecture $arch"
        exit 1
        ;;
    esac
    ;;
  *)
    log_error "unsupported architecture $arch"
    exit 1
    ;;
esac
expected_bootstrap_version_digest=${bootstrap_sha}
log_info "Downloading bootstrap version '${bootstrap_version}' of cosign to verify version to be installed...\n      https://github.com/sigstore/cosign/releases/download/${bootstrap_version}/${bootstrap_filename}"
curl -sL https://github.com/sigstore/cosign/releases/download/${bootstrap_version}/${bootstrap_filename} -o cosign
shaBootstrap=$(shaprog cosign);
if [[ $shaBootstrap != ${expected_bootstrap_version_digest} ]]; then
  log_error "Unable to validate cosign version: '${COSIGN_RELEASE}'"
  exit 1
fi
chmod +x cosign
# If the bootstrap and specified `cosign` releases are the same, we're done.
if [[ ${COSIGN_RELEASE} == ${bootstrap_version} ]]; then
  log_info "bootstrap version successfully verified and matches requested version so nothing else to do"
  exit 0
fi
semver='^v([0-9]+\.){0,2}(\*|[0-9]+)$'
if [[ ${COSIGN_RELEASE} =~ $semver ]]; then
  log_info "Custom cosign version '${COSIGN_RELEASE}' requested"
else
  log_error "Unable to validate requested cosign version: '${COSIGN_RELEASE}'"
  exit 1
fi
# Download custom cosign
log_info "Downloading platform-specific version '${COSIGN_RELEASE}' of cosign...\n      https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_filename}"
curl -sL https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_filename} -o cosign_${COSIGN_RELEASE}
shaCustom=$(shaprog cosign_${COSIGN_RELEASE});
# same hash means it is the same release
if [[ $shaCustom != $shaBootstrap ]]; then
  if [[ ${COSIGN_RELEASE} == 'v0.6.0' && ${RUNNER_OS} == 'Linux' ]]; then
    # v0.6.0's linux release has a dependency on `libpcsclite1`
    log_info "Installing libpcsclite1 package if necessary..."
    set +e
    sudo dpkg -s libpcsclite1
    if [ $? -eq 0 ]; then
        log_info "libpcsclite1 package is already installed"
    else
         log_info "libpcsclite1 package is not installed, installing it now."
         sudo apt-get update -q -q
         sudo apt-get install -yq libpcsclite1
    fi
    set -e
  fi
  if [[ ${COSIGN_RELEASE} == 'v0.6.0' ]]; then
    log_info "Downloading detached signature for platform-specific '${COSIGN_RELEASE}' of cosign...\n      https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_v060_signature}"
    curl -sL https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_v060_signature} -o ${desired_cosign_filename}.sig
  else
    log_info "Downloading detached signature for platform-specific '${COSIGN_RELEASE}' of cosign...\n      https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_filename}.sig"
    curl -sLO https://github.com/sigstore/cosign/releases/download/${COSIGN_RELEASE}/${desired_cosign_filename}.sig
  fi
  if [[ ${COSIGN_RELEASE} < 'v0.6.0' ]]; then
    RELEASE_COSIGN_PUB_KEY=https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_RELEASE}/.github/workflows/cosign.pub
  else
    RELEASE_COSIGN_PUB_KEY=https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_RELEASE}/release/release-cosign.pub
  fi
  log_info "Using bootstrap cosign to verify signature of desired cosign version"
  ./cosign verify-blob --key $RELEASE_COSIGN_PUB_KEY --signature ${desired_cosign_filename}.sig cosign_${COSIGN_RELEASE}
  rm cosign
  mv cosign_${COSIGN_RELEASE} cosign
  chmod +x cosign
  export PATH=${INSTALL_DIR}:$PATH

  log_info "Installation complete!"
fi
