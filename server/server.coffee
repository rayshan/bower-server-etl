# Vendor
express = require 'express'
app = express()

compress = require 'compression'
moment = require 'moment'
limiter = require 'express-limiter'
p = require 'path'

# Custom
config = require "./config"
ga = require "./ga"
cache = require './cache'

# ==========

###
# Middleware
###

# serve requests on shan.io/bower
rewriter = express.Router()
rewriter.use (req, res, next) ->
  req.url = req.url.replace '/bower', ''
  next()
  return

# TODO
# rate limiter
#limiter = limiter(app, cache.db)
#limiter {
#  path: '/api/action'
#  method: 'get'
#  lookup: ['connection.remoteAddress']
#  # total: 60 * 60 / 5 # 1 request every 5 seconds
#  total: 150
#  expire: 1000 * 60 * 60 # per hour
#}

###
# API
###

dataApi = express.Router()

# invoked when /:type present in path
dataApi.param 'type', (req, res, next, id) ->
  # add 'all' to valid query types b/c all isn't used for caching
  validTypes = ga.validQueryTypes.concat 'all'
  if validTypes.indexOf(id) is -1
    err = new Error "[ERROR] wrong request data type."
    console.error err
    res.json 500, {error: err.message}
  else
    req.type = id
    next()
  return

dataApi.route p.join config.apiBaseUri, '/data/:type'
  .all (req, res, next) -> # req logger for api only
    console.log req.method, req.type, req.path
    next()
    return
  .get (req, res) ->
    if cache.allCached()
      cache.fetch(req.type).then (data) ->
        # enable caching
        res.set 'cache-control', 'public, max-age=86400' # 1 day
        res.set 'expires', moment().add('days', 1).utc().format 'ddd, DD MMM YYYY HH:mm:ss [GMT]' # RFC2616, +1 day from now
        res.set 'last-modified', cache.lastCachedTime().RFC2616

        # enable CORS so other websites can embed API results
        res.set "Access-Control-Allow-Origin", "*"
        res.set "Access-Control-Allow-Headers", "X-Requested-With"

        res.json data
        return
    else
      err = new Error "[ERROR] request was made when fetch/cache was in progress."
      console.error err
      res.json 503, { # Service Unavailable (temporary)
        error: "Server is fetching & caching data, should be done soon. Please try again later."
      }
    return

###
# Server
###

# Only for prod env
if process.env.NODE_ENV is 'production'
  app.disable 'x-powered-by' # don't broadcast it's an express app
  app.enable 'trust proxy' # tell express it's behind nginx reverse proxy & trust X-Forwarded-* headers
  app.use rewriter # serve requests on shan.io/bower

staticAssetPath = p.join __dirname, '../public', if process.env.NODE_ENV is 'production' then '/dist' else ''

# all env
app.use compress() # gzip static content
app.use dataApi
app.use express.static staticAssetPath, {maxAge: 2592000000}
# serve static assets; 30 days in ms

start = ->
  port = process.env.PORT || config.port
  # heroku dynamically assigns a port, don't set env var if deploying on heroku
  app.listen port, -> console.info "[INFO] listening on port #{ port }."; return
  return

module.exports =
  start: start