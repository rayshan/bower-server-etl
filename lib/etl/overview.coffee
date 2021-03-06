# vendor
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
# using this instead of http.get to not deal w/ streams

# custom
util = require "bUtil"
cache = require "cache"

# ==========

etl = {}
etl.name = 'overview'

etl.extract = ->
  util.etlLogger 'extract', @name

  request.getAsync {url: 'https://bower.herokuapp.com/packages', json: true}
    .spread (res, body) -> totalPackages: body.length
    .catch (err) ->
      throw new Error "Can't extract package count from bower registry, err = #{ err }."

etl.transform = (data) -> data # nothing to transform

etl.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = etl
