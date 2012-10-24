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

task 'browser-test', 'Create browser test', ->
  browserTest()

task 'jasmine-runner', 'Create runners from Jasmine tests (experimental)', ->
  docs ->
    jasmineRunners()

task 'all', 'All tasks', ->
  cleanCompile ->
    test ->
      docs ->
        jasmineRunners()

clean = (callback) ->
  console.log 'clean'
  eachAsync ['build', 'docs'],
    (dir, callback) ->
      exec "rm -rf #{dir}", handleExec callback
    callback

compile = (callback) ->
  console.log 'compile'
  exec "coffee  -o build -j  jsondrop.js -c src/jsondrop-*.coffee src/jsondrop.coffee",
    handleExec callback

cleanCompile = (callback) ->
  clean ->
    compile callback

test = (callback) ->
  console.log 'test'
  exec "jasmine-node --coffee --test-dir specs",
    handleExec (stdout) ->
      console.log stdout
      return callback() if callback

docs = (callback) ->
  console.log 'docs'
  eachAsync ['src', 'specs'],
    (dir, callback) ->
      exec "docco #{dir}/*", handleExec callback
    callback

jasmineRunners = (callback) ->
  console.log 'jasmine-runner'
  exec "coffee -c -o docs/lib specs/*", handleExec ->
    exec "cp jasmine-lib/* docs/lib/", handleExec ->
      exec "ls specs/*.coffee", handleExec (stdout) ->
        eachSerial stdout.trim().split(/\s+/),
          (spec, callback) ->
            # TODO Some file API?
            specParts = spec.replace('\.coffee', '').split('/')
            specName = specParts[specParts.length - 1]
            exec "bash create-spec-runner.sh #{specName}", handleExec callback
          callback

browserTest = (callback) ->
  exec "coffee -c -o build/test test/*", handleExec ->
    exec "cp test/html/* build/test", handleExec ->
      connect = require('connect')
      connect.createServer(
              connect.static __dirname
      ).listen 8080
      console.log 'Browse http://localhost:8080/build/test/browser-test.html to run browser tests'
      return callback() if callback

# Just testing...
task 'cleanSerial', 'Clean build dirs', ->
   eachSerial ['build', 'docs'],
     (dir, callback) ->
       exec "rm -rf #{dir}", handleExec callback
     null

handleExec = (callback) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stderr
    if callback
      callback stdout
    else
      console.log stdout

# TODO make an underscore extension for the following async tasks or use async directly
eachAsync = (arr, iterator, callback) ->
  complete = _.after arr.length, () ->
    return callback() if callback
  _.each arr, (item) ->
    iterator item, complete

eachSerial = (arr, iterator, callback) ->
  if not arr then return callback()
  serialized = _.reduceRight arr,
    (memo, item) -> _.wrap memo, (callback) -> iterator item, callback
    () -> return callback() if callback
  serialized()
