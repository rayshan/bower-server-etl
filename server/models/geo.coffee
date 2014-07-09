# vendor
Promise = require 'bluebird'

# custom
util = require "bUtil"
ga = require "googleAnalytics"
cache = require "cache"
geo = require "geo"

# ==========

_gaQueryObj =
# monthly active users
  'ids': 'ga:' + config.ga.profile
  'start-date': '30daysAgo'
  'end-date': 'yesterday'
  'metrics': 'ga:users'
  'dimensions': 'ga:country'
  'sort': '-ga:users'

model = {}
modelName = 'geo'

model.extract = ->
  util.etlLogger 'extract', modelName
  ga.gaRateLimiter.removeTokensAsync 1 # don't hammer GA server w/ too many concurrent reqs
    .then ga.fetch _gaQueryObj

model.transform = (data) ->
  util.etlLogger 'transform', modelName

  geoPromises = []

  # remove (not set) country & country w/ just 1 user
  current = data.rows.filter (country) ->
    country[0] isnt "(not set)" and +country[1] > 1

  result = current.map (d) ->
    # not including name: d[0] to trim size
    isoCode: geo.getCode d[0] # get ISO 3166-1 alpha-3 code
    users: +d[1]

  result.forEach (country) ->
    geoPromise = geo.getPop(country.isoCode)
      .then (pop) ->
        country.density = Math.ceil(country.users / pop * 1000000) # per 1mil internet users
        return
      .catch (err) -> console.error err; return
    geoPromises.push geoPromise
    return

  Promise.all geoPromises
    .call 'sort', (a, b) -> b.density - a.density
    .then -> result

model.load = (data) ->
  util.etlLogger 'load', modelName
  cache.cache modelName, data

module.exports = model