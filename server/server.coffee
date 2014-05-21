# Vendor
express = require 'express'
compress = require 'compression'
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
      cache.fetch(req.type).then (data) -> res.json data; return
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

app = express()

# Only for prod env
if process.env.NODE_ENV is 'production'
  app.disable 'x-powered-by' # don't broadcast it's an express app
  app.enable 'trust proxy' # tell express it's behind nginx reverse proxy & trust X-Forwarded-* headers
  app.use rewriter # serve requests on shan.io/bower

# all env
app.use compress() # gzip static content
app.use dataApi
app.use express.static p.join __dirname, '../public' # serve static assets

module.exports =
  start: ->
    port = process.env.APP_PORT
    app.listen port, ->
      console.info "[INFO] listening on port #{ port }."; return