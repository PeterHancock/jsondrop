#! /bin/bash

function failOnError {
    if [ "$?" != "0" ]; then
        echo "FAIL: "$1
        exit $?
    fi
}

#Install tools and pull dependencies
npm install

failOnError "Unable to npm"

cake $@
