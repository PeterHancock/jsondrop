# Don't forget to 'npm install' first!

{exec} = require 'child_process'

_ = require 'underscore' 

task 'clean', 'Clean build dirs', ->
   clean()

task 'compile', 'Compile the coffee script src', ->
  cleanCompile()

task 'test', 'Tests', ->
  cleanCompile ->
    test()

task 'docs', 'Create documentation', ->
  docs()

task 'jasmine-runner', 'Create runners from Jasmine tests (experimental)', ->
  docs ->
    jasmineRunners()

task 'all', 'All tasks', ->
  all()

task 'browser-test', 'Create browser test', ->
  all ->
    browserTest()

failOr = (callback) ->
  (err) ->
    throw err if err
    return callback() if callback

all = (callback) ->
  cleanCompile ->
    test ->
      docs ->
        jasmineRunners callback

clean = (callback) ->
  console.log 'clean'
  eachAsync ['build', 'docs'],
    (dir, callback) ->
      shell "rm -rf #{dir}", failOr callback
    failOr callback

compile = (callback) ->
  console.log 'compile'
  shell "coffee  -o build -j  jsondrop.js -c src/jsondrop-*.coffee src/jsondrop.coffee",
    failOr callback

cleanCompile = (callback) ->
  clean ->
    compile callback

test = (callback) ->
  console.log 'test'
  shell "jasmine-node --coffee --test-dir specs", failOr callback

docs = (callback) ->
  console.log 'docs'
  eachAsync ['src', 'specs'],
    (dir, callback) ->
      shell "docco #{dir}/*", failOr callback
    failOr callback

jasmineRunners = (callback) ->
  console.log 'jasmine-runner'
  shell "coffee -c -o docs/lib specs/*", failOr ->
    shell "cp jasmine-lib/* docs/lib/", failOr ->
      shellForStdin "ls specs/*.coffee", (err, stdout) ->
        throw err if err
        eachSerial stdout.trim().split(/\s+/),
          (spec, callback) ->
            # TODO Some file API?
            specParts = spec.replace('\.coffee', '').split('/')
            specName = specParts[specParts.length - 1]
            shell "bash create-spec-runner.sh #{specName}", failOr callback
          failOr callback

browserTest = (callback) ->
  shell "coffee -c -o build/test test/*", failOr ->
    shell "cp test/html/* build/test", failOr ->
      connect = require('connect')
      connect.createServer(
              connect.static __dirname
      ).listen 8080
      console.log 'Browse http://localhost:8080/build/test/browser-test.html to run browser tests'
      return callback() if callback

shell = (cmd, callback) ->
  exec cmd, (err, stdout, stderr) ->
    console.log stdout + stderr
    callback err

shellForStdin = (cmd, callback) ->
  exec cmd, (err, stdout, stderr) ->
    console.log stderr
    callback err, stdout

# TODO make an underscore extension for the following async tasks or use async directly
eachAsync = (arr, iterator, callback) ->
  complete = _.after arr.length, callback
  _.each arr, (item) ->
    iterator item, (err) ->
      if err
        callback(err)
        callback = () ->
      else
        complete()

eachSerial = (arr, iterator, callback) ->
  if not arr then return callback()
  serialized = _.reduceRight arr,
    (memo, item) -> _.wrap memo,
      (next) -> iterator item, (err) ->
        if err
          callback(err)
        else
          next()
    callback
  serialized()

