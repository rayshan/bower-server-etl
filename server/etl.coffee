# data ETL

# vendor
Promise = require 'bluebird'
later = require 'later'
moment = require 'moment'

# custom
models = require 'models'
cache = require 'cache'
ga = require 'googleAnalytics'

# ==========

execute = ->
  # always flush db even on prod due to infrequent deploys & data schema still in flux
  cache.db.flushdb() # if process.env.NODE_ENV is 'development'

  _fetchPromises = []
  # need delay to ensure google server knows about auth before executing queries
  ga.authPromise.delay(2000).then ->
    models.modelRegistry.map (modelName) ->
      fetchPromise = models[modelName].extract().bind models[modelName]
        .then models[modelName].transform
        .then models[modelName].load
      _fetchPromises.push fetchPromise
      return

    Promise.all _fetchPromises
      .then ->
        lastCachedTimeUnix = JSON.stringify moment().unix()
        cache.db.setAsync "lastCachedTimeUnix", lastCachedTimeUnix
        console.info "[SUCCESS] cached all data @ #{ moment.unix(lastCachedTimeUnix).format 'LLLL' }"
#        console.log gh.noData.bowerRegistry
#        console.log gh.noData.github
        cache.allCached.set true
        return
      .catch (err) -> console.error err; return

  return

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
  execute: execute
