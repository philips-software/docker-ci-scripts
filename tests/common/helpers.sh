#!/bin/bash

function assert_failure {
  [ "$status" -eq 1 ]
}

function assert_success {
  [ "$status" -eq 0 ]
}

