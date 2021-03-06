# Don't forget to 'npm install' first!

# Dependencies
{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
_ = require 'underscore' 

# Tasks
task 'clean', 'Clean build dirs', ->
   clean()

task 'compile', 'Compile the coffee script src', ->
  cleanCompile()

task 'test', 'Tests', ->
  depends cleanCompile, test

task 'docs', 'Create documentation', ->
  docs()

task 'jasmine-runner', 'Create runners from Jasmine tests (experimental)', ->
  depends docs, jasmineRunners

task 'all', 'All tasks', ->
  all()

task 'quickstart', 'Create quick start page', ->
  depends all, quickstart

task 'browser-test', 'Create browser test', ->
  depends all, browserTest

task 'browser-test-quick', 'Create browser test', ->
  depends clean, compile, browserTest

task 'start-server', 'Start a localhost web app serving .', ->
  startServer()

all = (callback) ->
  depends clean, compile, test, docs, jasmineRunners, failOr callback

clean = (callback) ->
  console.log 'clean'
  eachAsync ['build', 'docs'],
    (dir, callback) ->
      shell "rm -rf #{dir}", failOr callback
    failOr callback

compile = (callback) ->
  console.log 'compile'
  shell "coffee -o build -j jsondrop.js -c src/*.coffee",
    failOr callback

cleanCompile = (callback) ->
  depends clean, compile, callback

test = (callback) ->
  console.log 'test'
  shell "jasmine-node --verbose --coffee --test-dir specs", failOr callback

docs = (callback) ->
  console.log 'docs'
  eachAsync ['src', 'specs'],
    (dir, callback) ->
      shell "docco #{dir}/*", failOr callback
    failOr callback

jasmineRunners = (callback) ->
  console.log 'jasmine-runner'
  shell "coffee -c -o docs/lib specs/*", failOr ->
    eachAsync ['cp jasmine-lib/*.js docs/lib/', 'cp build/*.js docs/lib/'],
      (cmd, callback) ->
        shell cmd, failOr callback
      failOr ->
        shellForStdin "ls specs/*.coffee", (err, stdout) ->
          throw err if err
          eachSerial stdout.trim().split(/\s+/),
            (spec, callback) ->
              createRunner spec, failOr callback
            failOr callback

createRunner = (spec, callback) ->
  specName = path.basename(spec).replace '\.coffee', ''
  footer = _.reduce [
        '//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.2/underscore-min.js',
        '//cdnjs.cloudflare.com/ajax/libs/async/0.2.7/async.min.js',
        '//cdnjs.cloudflare.com/ajax/libs/jasmine/1.3.1/jasmine.js',
        '//cdnjs.cloudflare.com/ajax/libs/jasmine/1.3.1/jasmine-html.js',
        'lib/jsondrop.js',
        "lib/#{specName}.js",
        'lib/jasmine-runner.js'],
    (memo, script) -> memo + '\n#' + "<script src='#{script}'></script>",
    '\n#<span class="version">FILLED IN AT RUNTIME</span>\n#<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/jasmine/1.3.1/jasmine.css"/>'
  runnerName = specName + '-runner.coffee'
  runner = "build/#{runnerName}"
  shell "cp #{spec} #{runner}", failOr ->
    fs.appendFile runner, footer, failOr ->
      shell "docco #{runner}", failOr ->
        shell "rm #{runner}", failOr callback

quickstart = (callback) ->
  console.log 'quick start'
  shell "coffee -c -o docs/lib quickstart/quickstart.coffee", failOr ->
    createRunner 'quickstart/quickstart.coffee', failOr callback

browserTest = (callback) ->
  shell "coffee -c -o build/browser-test browser-test/*", failOr ->
    shell "cp browser-test/html/* build/browser-test", failOr callback

#########################################################
# Build utilities

depends = (tasks..., callback) ->
  throw 'callback not defined' unless callback
  depends.ran = [] unless depends.ran
  eachSerial tasks,
    (task, callback) ->
      return callback() if _.contains(depends.ran, task)
      depends.ran.push task
      task callback
    callback

failOr = (callback) ->
  (err) ->
    throw err if err
    return callback() if callback

#Shell commands
shell = (cmd, callback) ->
  exec cmd, (err, stdout, stderr) ->
    console.log stdout + stderr
    callback err

shellForStdin = (cmd, callback) ->
  exec cmd, (err, stdout, stderr) ->
    console.log stderr
    callback err, stdout

#Start a localhost web server
startServer = (callback) ->
  connect = require('connect')
  connect.createServer(
          connect.static __dirname
  ).listen 8080
  return callback?()

#Iteration methods
eachAsync = (arr, iterator, callback) ->
  if not arr then return callback()
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
