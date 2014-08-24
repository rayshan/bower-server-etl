# Vendor
Promise = require 'bluebird'
redis = Promise.promisifyAll require 'redis'
moment = require 'moment'

# Custom
ga = require 'googleAnalytics'
gh = require 'github'

# ==========

allCached =
  value: false
  set: (status) -> @value = status; return
  get: -> @value

# ==========
# cache data fetch responses via redis

fetch = (opType, models) ->
  console.info "[INFO] fetching data [#{ models }] from cache."

  switch opType
    when 'single' # fetch individual data source
      db.existsAsync(models).then (res) ->
        if res is 1 # already cached
          db.getAsync(models).then (res) -> JSON.parse res
        else # not cached
          throw new Error "[INFO] [#{ models }] not cached."

    when 'multi' # fetch combined data source, 'all'
      db.mgetAsync(models).then (res) ->
        result = {}
        models.forEach (modelName, i) -> result[modelName] = JSON.parse res[i]; return
        result.dataEndTime = moment().subtract(1, 'days').endOf('day').utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]'
        # yesterday
        result

cache = (key, data) ->
  cacheDataP = db.setAsync key, JSON.stringify data
  # delete key at start of next day
  expireAtP = db.expireatAsync key, moment().add(1, 'days').startOf('day').unix()

  Promise.join cacheDataP, expireAtP, ->
    console.info "[SUCCESS] ETL complete for [#{ key }]."
    return

# ==========

# defaults to db 0
if process.env.NODE_ENV is 'development'
  db = redis.createClient config.cache, socket_keepalive: false # default of true may create multiple connect events
else
  # using Redis Labs Redis Cloud, req auth
  db = redis.createClient config.cache.port, config.cache.hostname, no_ready_check: true
  db.auth config.cache.auth.split(":")[1]

db.on "error", (err) -> console.error err; return

# ==========

module.exports =
  db: db
  cache: cache
  fetch: fetch
  allCached: allCached
