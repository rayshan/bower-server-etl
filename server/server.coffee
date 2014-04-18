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
# Server & API
###

app = express()
dataApi = express.Router()

# invoked when /:type present in path
dataApi.param 'type', (req, res, next, id) ->
  if ga.validQueryTypes.indexOf(id) is -1
    err = new Error "Wrong request data type."
    console.log "ERROR: #{ err.message }"
    res.json 500, {error: err.message}
  else
    req.type = id
    next()
  return

dataApi.route '/data/:type'
.all (req, res, next) -> # req logger
  console.log req.method, req.type, req.path
  next()
  return
.get (req, res) ->
  cache.fetch(req.type).then (data) -> res.json data; return
  return

app.use compress # gzip static content
app.use dataApi
app.use express.static p.join __dirname, '../public'

module.exports =
  start: ->
    port = process.env.APP_PORT
    app.listen port, ->
      console.log "INFO: listening on port #{ port }."; return