#! /bin/bash

# TODO use Cake

function failOnError {
    if [ "$?" != "0" ]; then
        echo "FAIL: "$1
        exit $?
    fi
}

#Install tools and pull dependencies
#easy_install pygments # <- Only required once
npm install

failOnError "Unable to npm"

cake $@
