#!/bin/bash -e

function check {
    unset RESULT
    RESULT=$(${1})
    if [ "${2}" = "true" ]
    then
      if [ -z "${RESULT}" ]
      then
        exit 1
      fi
    fi
}
