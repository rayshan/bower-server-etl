server = require './server/server'
cache = require './server/cache'

# ==========

# run all queries & populate cache
cache.db.on "connect", cache.init

# start server
server.start()