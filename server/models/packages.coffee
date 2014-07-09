# vendor
_ = require 'lodash-node'
Promise = require 'bluebird'

# custom
util = require "bUtil"
ga = require "googleAnalytics"
gh = require 'github'
cache = require "cache"

# ==========

# 'package' is a reserved word in JS
# only want to pull packages w/ >= 5 installs, which is around the 3500th pkg sorted by installs

_gaQueryObj =
  'ids': 'ga:' + config.ga.profile
  'dimensions': 'ga:pagePathLevel2,ga:nthDay'
  'metrics': 'ga:pageviews'
  'filters': 'ga:pagePathLevel1=@installed;ga:pageviews>=100'
  'start-date': '14daysAgo'
  'end-date': 'yesterday'
  # =@ contains substring, don't use url encoding '%3D@'; test for specific pkg, add ;ga:pagePathLevel2==/video.js/ (; = AND)
  # 'sort': '-ga:pageviews'
  # 'max-results': 100 # desired result quantity * 2 due to ga:nthWeek dim doubling # of rows returned

model = {}
modelName = 'packages'

model.extract = ->
  util.etlLogger 'extract', modelName
  ga.gaRateLimiter.removeTokensAsync 1 # don't hammer GA server w/ too many concurrent reqs
  .then ga.fetch _gaQueryObj

model.transform = (data) ->
  util.etlLogger 'transform', modelName

  # TODO: ranking range as arg

  dataNested = _.groupBy data.rows, (d) -> d[0]
  data = Object.keys(dataNested).map (name) ->
    # extract daily install counts to an array
    installs = []
    dataNested[name].forEach (d) -> installs[+d[1]] = +d[2]; return
    # ensure array has 14 days of data
    installs = [0..13].map (i) -> if installs[i] then installs[i] else 100

    name: util.removeSlash name
    installs: installs

  console.log data['angular']

  sortFunc = (period, currentOrPrior) -> (a, b) ->
    reduceFunc = (a, b, i) ->
      if (if currentOrPrior is 'current' then i >= period else i < period) then a + b else a
    (b.installs.reduce reduceFunc, 0) - (a.installs.reduce reduceFunc, 0)

  # find prior period rankings
  data.sort sortFunc 7, 'prior'
  data.forEach (d, i) -> d.rank = []; d.rank.push i + 1
  # find current period rankings
  data.sort sortFunc 7, 'current'
  data.forEach (d, i) -> d.rank.push i + 1

  # TODO: force cache only top 100; to be removed
  data.splice 100

  ghPromises = []
  data.forEach (pkg) -> ghPromises.push gh.appendData pkg; return
  Promise.all(ghPromises).then -> data

model.load = (data) ->
  util.etlLogger 'load', modelName
  cache.cache modelName, data

module.exports = model