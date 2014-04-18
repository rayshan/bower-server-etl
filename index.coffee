server = require './server/server'
cache = require './server/cache'

# ==========

cache.db.on "connect", cache.init
server.start()