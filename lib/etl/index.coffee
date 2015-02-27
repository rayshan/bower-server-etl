# data ETL

# vendor
fs = require 'fs'
Promise = require 'bluebird'
later = require 'later'
moment = require 'moment'

# custom
cache = require 'cache'

# ==========

# load all files under models dir

modelRegistry = []
models = {}

override = [
  'commands.coffee'
  'geo.coffee'
  'overview.coffee'
  'packages.coffee'
  'users.coffee'
#  'stats_env.coffee'
]

modelFiles = if override.length isnt 0 then override else fs.readdirSync __dirname

# register & export models
modelFiles
  .filter (fileName) ->
    fileName.match(/.+\.coffee/g) isnt null && fileName isnt 'index.coffee'
  .forEach (fileName) ->
    name = fileName.replace '.coffee', ''
    modelRegistry.push name
    models[name] = require './' + fileName
    return

console.info "modelRegistry = #{modelRegistry}"

# ==========

execute = ->
  # always flush db even on prod due to infrequent deploys & data schema still in flux
  cache.db.flushdb() # if process.env.NODE_ENV is 'development'

  _fetchPromises = []

  modelRegistry.map (modelName) ->
    fetchPromise = models[modelName]
      .extract()
      .bind models[modelName]
      .then models[modelName].transform
      .then models[modelName].load
    _fetchPromises.push fetchPromise
    return

  Promise.all _fetchPromises
    .then ->
      lastCachedTimeUnix = JSON.stringify moment().unix()
      cache.db.setAsync "lastCachedTimeUnix", lastCachedTimeUnix
      console.info "[SUCCESS] cached all data @ #{ moment.unix(lastCachedTimeUnix).format 'LLLL' }"
      cache.allCached.set true
      return
    .catch (err) ->
      console.error "Error during ETL, err = #{err}"

# ==========

# cron job to get data ready so 1st user of every day don't have to wait long

# set later to use local time (default = UTC, later doesn't support specific tz)
later.date.localTime()

# catch/fetch a little later than midnight in case there's a midnight refresh
schedule = later.parse.recur().on('00:01:00').time() # 0:05; 24-hour format

#console.info later.schedule(schedule).next 5 # print next 5 occurrences of later schedule
timer = later.setInterval execute, schedule # execute init on schedule

# ==========

module.exports =
  modelRegistry: modelRegistry
  execute: execute
