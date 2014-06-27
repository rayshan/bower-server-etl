# vendor
if process.env.NODE_ENV is 'production'
  require 'newrelic'

# custom
server = require './server/server'
cache = require './server/cache'

# ==========

# run all queries & populate cache
cache.db.on "connect", ->
  console.info "[SUCCESS] Connected to Redis."
  cache.init()
  return

# start server
server.start()

# ==========

# graceful shutdown
process.on 'exit', ->
  cache.db.quit()
  cache.db.shutdown() if process.env.NODE_ENV is 'development'
  console.log '[INFO] Redis connection ended. Exiting stats.bower.io app.'
  return

# shutdown via Ctrl+C in dev
process.on 'SIGINT', ->
  console.log 'Gracefully shutting down from SIGINT (Crtl-C)'
  process.exit()
  return

# usually called with kill
process.on 'SIGTERM', ->
  console.log 'Parent SIGTERM detected (kill)'
  process.exit()
  return