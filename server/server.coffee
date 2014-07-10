# Vendor
express = require 'express'
app = express()

compress = require 'compression'
#limiter = require 'express-limiter'
p = require 'path'

# Custom
api = require 'serverApiRouter'
#cache = require 'cache'

# ==========

###
# Middleware
###

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
# Server
###

# Only for prod env
if process.env.NODE_ENV is 'production'
  app.disable 'x-powered-by' # don't broadcast it's an express app
  app.enable 'trust proxy' # tell express it's behind nginx reverse proxy & trust X-Forwarded-* headers

staticAssetPath = p.join __dirname, '../public', if process.env.NODE_ENV is 'production' then '/dist' else ''

# all env
app.use compress() # gzip static content
app.use api
app.use express.static staticAssetPath, {maxAge: 2592000000}
# serve static assets; 30 days in ms

start = ->
  port = process.env.PORT || config.port
  # heroku dynamically assigns a port, don't set env var if deploying on heroku
  app.listen port, -> console.info "[INFO] server listening on port #{ port }."; return
  return

module.exports =
  start: start