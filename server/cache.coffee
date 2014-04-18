# Vendor
redis = require 'redis'
rsvp = require "rsvp"

# Custom
ga = require './ga'
config = require "./config"

# ==========

# cache GA response via redis

fetch = (key) ->
  new rsvp.Promise (resolve, reject) ->
    db.exists key, (err, res) ->
      if err # redis err
        console.log "ERROR: redis - db.exists(#{ key }) - #{ err }"
        reject err
        return
      else if res is 1 # already cached
        console.log "INFO: cached / fetching [#{ key }] from cache."
        db.get key, (err, res) ->
          if err
            console.log "ERROR: redis - db.get(#{ key }) - #{ err }"
            reject err
          else resolve JSON.parse res
          return
        return
      else
        console.log "INFO: not cached / fetching [#{ key }] from GA."
        ga.authPromise.then(ga.fetch key) # .then transform
          .then (data) ->
            db.set key, JSON.stringify(data)
            resolve data
            return
          .catch (err) -> console.log "ERROR: ", err; return

init = ->
  # for testing
  ga.validQueryTypes.forEach (key) -> db.del key; return

  console.log "SUCCESS: Connected to Redis."
  ga.validQueryTypes.forEach (key) -> fetch key; return
  return

db = redis.createClient config.db.socket
db.on "error", (err) -> console.log err; return

module.exports =
  init: init
  fetch: fetch
  db: db