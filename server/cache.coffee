# Vendor
redis = require 'redis'
rsvp = require 'rsvp'
request = require 'request'

# Custom
ga = require './ga'
config = require "./config"

# ==========

# cache GA response via redis

fetch = (key) ->
  new rsvp.Promise (resolve, reject) ->
    db.exists key, (err, res) ->
      if err # redis err
        console.error "ERROR: redis - db.exists(#{ key }) - #{ err }"
        reject err
        return
      else if res is 1 # already cached
        console.info "[INFO] cached / fetching [#{ key }] from cache."
        db.get key, (err, res) ->
          if err
            console.error "ERROR: redis - db.get(#{ key }) - #{ err }"
            reject err
          else resolve JSON.parse res
          return
        return
      else # not cached
        console.info "[INFO] not cached / fetching [#{ key }] from GA."
        if key is 'overview'
          request {url: 'https://bower.herokuapp.com/packages', json: true}, (err, res, body) ->
            if err
              console.error "ERROR: can't fetch package count from bower registry, err = #{ err }"
              reject err
            else
              data = totalPkgs: body.length
              db.set key, JSON.stringify data
              resolve data
            return
        else
          ga.authPromise.then(ga.fetch key) # .then transform
            .then (data) ->
              db.set key, JSON.stringify data
              resolve data
              return
            .catch (err) -> console.error "ERROR: ", err; return

init = ->
  console.info "SUCCESS: Connected to Redis."

  # for dev; comment out for prod
  if process.env.NODE_ENV is 'dev'
    db.flushdb()

  ga.validQueryTypes.forEach (key) -> fetch key; return
  fetch 'overview'
  return

db = redis.createClient config.db.socket
db.on "error", (err) -> console.log err; return

module.exports =
  init: init
  fetch: fetch
  db: db