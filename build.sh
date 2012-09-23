#! /bin/bash

# TODO use Cake

# Clean
rm -rf build

# Compile
coffee -c -o build src/*

# Generate docs
docco src/*

# Test
jasmine-node --coffee  --test-dir specs

