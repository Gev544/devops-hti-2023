#!/bin/bash -ex

function check {
    unset RESULT
    RESULT=$(${1})
    echo $RESULT
    if [ "${2}" = "true" ]
    then
      if [ -z "${RESULT}" ]
      then
        exit 1
      fi
    fi
}
