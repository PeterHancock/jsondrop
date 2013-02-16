if global? and require? and module?
  exports = global
  exports._ = require('underscore')

class Mixin
  @mixin = (source) ->
    _.extend(@::, source)

Iterable =
  each: (iterator, callback) -> throw 'No each'

  eachSeries: (iterator, callback) -> throw 'No eachSeries'

  map: (mapTo, callback) ->
    @_mapCommon mapTo, callback, _.bind(@each, @)

  mapSeries: (mapTo, callback) ->
    @_mapCommon mapTo, callback, _.bind(@eachSeries, @)

  _mapCommon: (mapTo, callback, eachMethod) ->
    if not callback
      callback = mapTo
      mapTo = (element) -> element
    result = []
    collectElements = (element, node, index) ->
      result.push mapTo(element, node)
    eachMethod collectElements, (err) ->
      return callback(err) if err
      callback(null, result)


class Collections
  @eachAsync = (arr, iterator, callback) ->
    [iterator, callback] = Collections._eachParams(iterator, callback)
    if not arr then return callback()
    complete = _.after arr.length, callback
    _.each arr, (item, index) ->
      iterator item, index, (err) ->
        if err
          callback err
          callback = () ->
        else
          complete()

  @_eachParams = (iterator, callback) ->
    if not callback
      callback = iterator
      iterator = (fn, index, callback) ->
        fn(index, callback)
    [iterator, callback]

  @eachSeries = (arr, iterator, callback) ->
   if not arr then return callback()
   serialized = _.reduceRight arr,
     (memo, item, index) -> _.wrap memo,
      (next) -> iterator item, index, (err) ->
         if err
           callback err
         else
           setTimeout next, 0
     callback
   serialized()