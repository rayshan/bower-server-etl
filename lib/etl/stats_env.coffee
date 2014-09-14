# vendor
Promise = require 'bluebird'

# custom
util = require "bUtil"
ga = require "googleAnalytics"
cache = require "cache"
geo = require "geo"
db = require "models"

# ==========

_gaQueryObj =
  'ids': 'ga:' + config.ga.profile
  'start-date': '14daysAgo' # first day w/ significant env data # 2014-08-05
  'end-date': 'yesterday'
  'metrics': 'ga:users'
  'dimensions': 'ga:date,ga:dimension1,ga:dimension2,ga:dimension3'
  'sort': 'ga:date'
  'max-results': 10000

etl = {}
etl.name = 'stats_env'

etl.extract = ->
  util.etlLogger 'extract', @name
  ga.fetch _gaQueryObj

etl.transform = (data) ->
  util.etlLogger 'transform', @name

  # assign a key to each row array's item
  result = data.rows.map (row) ->
    date: row[0] # YYYYMMDD; Postgres parses date
    version_cli: row[1]
    version_node: row[2]
    os: row[3]
    users: +row[4]

  result

etl.load = (data) ->
  util.etlLogger 'load', @name

#  d = new Date()
#  d.setDate d.getDate() - 10

# doesn't work w/o id, see https://github.com/sequelize/sequelize/issues/1026
#  db.stats_env.destroy {
#    updated_at:
#      gt: d
#  }
#    .then ->

  # 2nd arg is callee model name, null b/c we're specifying table name
  db.client.query "DELETE FROM #{@name} WHERE date > current_date - 15", null, type: 'BULKDELETE'
    .bind etl
    .then (affectedRows) ->
      console.log "[SUCCESS] Deleted #{affectedRows} rows in #{@name}."
      db.stats_env.bulkCreate data
    .then (affectedRows) ->
      console.log "[SUCCESS] Inserted #{affectedRows.length} rows in #{@name}."
      return

module.exports = etl
