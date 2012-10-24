# Don't forget to 'npm install' first!

{exec} = require 'child_process'

_ = require 'underscore' 

task 'clean', 'Clean build dirs', ->
   clean()

clean = (callback) ->
  eachAsync ['build', 'docs'],
    (dir, callback) ->
      exec "rm -rf #{dir}", handleExec callback
    callback

# Just testing...
task 'cleanSerial', 'Clean build dirs', ->
   eachSerial ['build', 'docs'],
     (dir, callback) ->
       exec "rm -rf #{dir}", handleExec callback
     null

handleExec = (callback) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    return callback() if callback

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
