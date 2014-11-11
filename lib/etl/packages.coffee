# vendor
_ = require 'lodash-node'
Promise = require 'bluebird'

# custom
util = require "bUtil"
gaExtractor = require "googleAnalytics"
gh = require 'github'
cache = require "cache"

# ==========

# FYI 'package' is a reserved word in JS

_packageInstallsCutoff = 3

_gaFilters =
  installed: 'ga:pagePathLevel1=@installed'
  packageInstallsCutoff: "ga:pageviews>=#{_packageInstallsCutoff}"

# TODO remove _packageInstallsCutoff once caching everything, need to paginate through GA results

etl = {}
etl.name = 'packages'
etl.gaQueryObj =
  'dimensions': 'ga:pagePathLevel2,ga:nthDay'
  'metrics': 'ga:pageviews'
  'filters': "#{_gaFilters.installed};#{_gaFilters.packageInstallsCutoff}"
  'start-date': '15daysAgo'
  'end-date': '2daysAgo'
  # =@ contains substring, don't use url encoding '%3D@'; test for specific pkg, add ;ga:pagePathLevel2==/video.js/ (; = AND)
  # 'sort': '-ga:pageviews'

etl.extract = ->
  util.etlLogger 'extract', @name
  gaExtractor.extract @gaQueryObj

etl.transform = (data) ->
  util.etlLogger 'transform', @name

  console.info "[INFO] packages etl - received #{data.length} / #{data.totalResults} rows."

  dataNested = _.groupBy data, (d) -> d[0]
  data = Object.keys(dataNested).map (name) ->
    # extract daily install counts to an array
    installs = []
    dataNested[name].forEach (d) -> installs[+d[1]] = +d[2]; return # 1: nth day, 2: install count
    # ensure array has 14 days of data
    installs = [0..13].map (i) -> if installs[i] then installs[i] else _packageInstallsCutoff

    name: util.removeSlash name
    installs: installs

  sortFunc = (period, currentOrPrior) -> (a, b) ->
    reduceFunc = (a, b, i) ->
      if (if currentOrPrior is 'current' then i >= period else i < period) then a + b else a
    (b.installs.reduce reduceFunc, 0) - (a.installs.reduce reduceFunc, 0)

  # find prior period rankings
  data.sort sortFunc 7, 'prior'
  data.forEach (d, i) -> d.rank = [i + 1]
  # find current period rankings
  data.sort sortFunc 7, 'current'
  data.forEach (d, i) -> d.rank.push i + 1

  # TODO: force cache only top 100; to be removed
  data.splice 100

  ghPromises = (gh.appendData pkg for pkg in data)
  Promise.all(ghPromises).then -> data

etl.load = (data) ->
  util.etlLogger 'load', @name
  cache.cache @name, data

  # pluck
  # hmsetAsync packages:angular, {obj}
  # sorted set w/ ranking

module.exports = etl
