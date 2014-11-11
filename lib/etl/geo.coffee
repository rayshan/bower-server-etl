# vendor
Promise = require 'bluebird'

# custom
util = require "bUtil"
gaExtractor = require "googleAnalytics"
cache = require "cache"
geo = require "geo"

# ==========

etl = {}
etl.name = 'geo'
etl.gaQueryObj =
# monthly active users
  'start-date': '31daysAgo'
  'end-date': '2daysAgo'
  'metrics': 'ga:users'
  'dimensions': 'ga:country'
  'sort': '-ga:users'

etl.extract = ->
  util.etlLogger 'extract', @name
  gaExtractor.extract @gaQueryObj

etl.transform = (data) ->
  util.etlLogger 'transform', @name

  geoPromises = []

  # remove (not set) country & country w/ just 1 user
  current = data.filter (country) ->
    country[0] isnt "(not set)" and +country[1] > 1

  result = current.map (d) ->
    # not including name: d[0] to trim size
    isoCode: geo.getCode d[0] # get ISO 3166-1 alpha-3 code
    users: +d[1]

  result.forEach (country) ->
    geoPromise = geo.getPop country.isoCode
      .then (pop) ->
        country.density = Math.ceil(country.users / pop * 1000000) # per 1mil internet users
        return
      .catch (err) -> console.error err; return
    geoPromises.push geoPromise
    return

  Promise.all geoPromises
    .call 'sort', (a, b) -> b.density - a.density
    .then -> result

etl.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

module.exports = etl
