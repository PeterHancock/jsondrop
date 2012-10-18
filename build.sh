#! /bin/bash

# TODO use Cake

function failOnError {
    if [ "$?" != "0" ]; then
        echo "FAIL: "$1
        exit $?
    fi
}

# Clean
rm -rf build
rm -rf docs

#Install tools and pull dependencies
#easy_install pygments # <- Only required once
npm install

# Compile
coffee  -o build -j  jsondrop.js -c src/jsondrop-*.coffee src/jsondrop.coffee
failOnError "Could not compile src"

# Test
jasmine-node --coffee --test-dir specs
failOnError "Some tests failed"

# Generate docs
docco src/*
failOnError "Could not generate src docs"
docco specs/*
failOnError "Could not generate spec docs"

# Browser test
coffee -c -o build/test test/*
cp test/html/* build/test

# Experimental!!! create jasmine runners from specs that include docco
coffee -c -o docs/lib specs/*
cp jasmine-lib/* docs/lib/
for SPEC in $(ls specs/*.coffee); do
    SPEC=${SPEC%.coffee}
    SPEC=${SPEC#specs/}
    bash create-spec-runner.sh $SPEC
done

failOnError "Could not create some Jasmine test runner"
