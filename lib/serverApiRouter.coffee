# Vendor
p = require 'path'
Promise = require 'bluebird'
moment = require 'moment'
express = require 'express'

# Custom
cache = require 'cache'
modelRegistry = require('etl').modelRegistry

# ==========

api = express.Router()

# invoked when /:type present in path
api.param 'type', (req, res, next, id) ->
  # add 'all' to valid query types b/c all isn't used for caching
  if modelRegistry.indexOf(id) is -1 and id isnt 'all'
    err = new Error "Wrong request data type."
    console.error err
    res.json 500, {error: err.message}
  else
    req.type = id; next()
  return

api.route p.join config.apiBaseUri, '/data/:type'
  .all (req, res, next) -> # req logger for api only
    console.log req.method, req.type, req.path
    next()
    return
  .get (req, res) ->
    if cache.allCached.get()
      opType = if req.type is 'all' then 'multi' else 'single'
      models = if req.type is 'all' then modelRegistry else req.type
      getData = cache.fetch opType, models
      getTime = cache.db.getAsync("lastCachedTimeUnix")
      Promise.join getData, getTime, (data, lastCachedTime) ->
        # enable caching
        res.set 'cache-control', 'public, max-age=86400' # 1 day
        res.set 'expires', moment().add(1, 'days').utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]' # RFC2616, +1 day from now
        res.set 'last-modified', moment.unix(lastCachedTime).utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]'

        # enable CORS so other websites can embed API results
        res.set "Access-Control-Allow-Origin", "*"
        res.set "Access-Control-Allow-Headers", "X-Requested-With"

        res.json data
        return
      .catch (err) -> console.error err; return
    else
      console.error new Error "[ERROR] request was made when fetch/cache was in progress."
      res.json 503, { # Service Unavailable (temporary)
        error: "Server is processing data ETL, should be done very soon. Please try again later."
      }
    return

# TODO
# X-RateLimit-Limit: 20
# X-RateLimit-Remaining: 19
# X-Rate-Limit-Reset: twitter usex unix epoch seconds
# res.json 429, {error: 'Too Many Requests, please try again later. See X-RateLimit headers for more info'}

module.exports = api
