# Vendor
express = require 'express'
compress = require('compression')()
p = require 'path'

# Custom
config = require "./config"
ga = require "./ga"
cache = require './cache'

# ==========

###
# Middleware
###

rewriter = express.Router()
rewriter.use (req, res, next) ->
#  console.info "[INFO] rewriting #{ req.url } to:"
  req.url = req.url.replace '/bower', ''
#  console.info req.url
  next()
  return

###
# API
###

dataApi = express.Router()

# invoked when /:type present in path
dataApi.param 'type', (req, res, next, id) ->
  if ga.validQueryTypes.indexOf(id) is -1
    err = new Error "[ERROR] wrong request data type."
    console.error err
    res.json 500, {error: err.message}
  else
    req.type = id
    next()
  return

dataApi.route '/data/:type'
  .all (req, res, next) -> # req logger for api only
    console.log req.method, req.type, req.path
    next()
    return
  .get (req, res) ->
    cache.fetch(req.type).then (data) -> res.json data; return
    return

###
# Server
###

app = express()

# Only for prod env
if process.env.NODE_ENV is 'prod'
  app.disable 'x-powered-by' # don't broadcast it's an express app
  app.enable 'trust proxy' # tell express it's behind nginx reverse proxy & trust X-Forwarded-* headers
  app.use rewriter # serve requests on shan.io/bower

# prod & dev env
app.use compress # gzip static content
app.use dataApi
app.use express.static p.join __dirname, '../public' # serve static assets

module.exports =
  start: ->
    port = process.env.APP_PORT
    app.listen port, ->
      console.info "[INFO] listening on port #{ port }."; return