{exec} = require 'child_process'

exec 'npm install', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

_ = require 'underscore' 

task 'clean', 'Clean build dirs', ->
   clean()

clean = (callback) ->
  exec 'rm -rf build', handleExec ->
    exec 'rm -rf docs', handleExec callback      

handleExec = (callback) ->
    (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        return callback() if callback
