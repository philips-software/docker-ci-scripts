#!/bin/bash

# https://github.com/JeroenKnoops/forest-bash/blob/master/messages.sh

set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

function big() {
    set +e
    hash figlet &> /dev/null
    if [ $? -eq 1 ]; then
        echo >&2 "$1"
    else
        figlet -f small "$1"
    fi
    set -e
}

function info {
  echo "   INFO:    ${YELLOW}$1${RESET}"
}

function success {
  echo "   SUCCESS: ${GREEN}$1${RESET}"
  echo "   ====================================================================================="
}

function error {
  echo "   ERROR:   ${RED}$1${RESET}"
  exit 1
}

function warn {
  echo "   WARN:    ${BLUE}$1${RESET}"
}

function delimiter {
  echo "   -------------------------------------------------------------------------------------"
}
