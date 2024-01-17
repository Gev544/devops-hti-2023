#!/bin/bash
function error_handler {
        if [ $? -eq 0 ]; then
              echo " Succesful "
        else
              echo "Something went wrong with $1 $2"
              exit 1
        fi

}

