# vendor
Promise = require 'bluebird'
moment = require 'moment'

# custom
util = require "bUtil"
gaExtractor = require "googleAnalytics"
cache = require "cache"
geo = require "geo"
db = require "models"

# ==========

# 14 / 1 gets 14 days of data; 20 / 1 gets 20 days
_gaStartDate = moment().subtract(20, 'days').format "YYYY-MM-DD"
_gaEndDate = moment().subtract(1, 'days').format "YYYY-MM-DD"

etl = {}
etl.name = 'stats_env'
etl.gaQueryObj =
  # not doing 15 days / 2 days ago to be safe b/c always restating previous 14 days of history
  # first day w/ significant env data # 2014-08-05
  'start-date': _gaStartDate
  'end-date': _gaEndDate
  'metrics': 'ga:users'
  'dimensions': 'ga:date,ga:dimension1,ga:dimension2,ga:dimension3'
  'sort': 'ga:date'

etl.extract = ->
  util.etlLogger 'extract', @name
  gaExtractor.extract @gaQueryObj

etl.transform = (data) ->
  util.etlLogger 'transform', @name

  # assign a key to each row array's item
  result = data.map (row) ->
    date: row[0] # YYYYMMDD; Postgres parses date
    os: row[1]
    version_node: row[2]
    version_cli: row[3]
    users: +row[4]

  result

etl.load = (data) ->
  util.etlLogger 'load', @name

# doesn't work w/o id, see https://github.com/sequelize/sequelize/issues/2561
  #  d = new Date()
  #  d.setDate d.getDate() - 15

#  db.stats_env.destroy where: updated_at: gt: d
#    .bind etl
#    .then (affectedRows) ->
#      console.log "[SUCCESS] Deleted #{affectedRows} rows in #{@name}."

  # 2nd arg is callee model name, null b/c we're specifying table name
  db.client.query "DELETE FROM #{@name} WHERE date >= '#{_gaStartDate}'", null, type: 'BULKDELETE'
    .bind etl
    .then (affectedRows) ->
      console.log "[SUCCESS] Deleted #{affectedRows} rows in #{@name}."; return
    .then ->
      db.stats_env.bulkCreate data
    .then (affectedRows) ->
      console.log "[SUCCESS] Inserted #{affectedRows.length} rows in #{@name}."
      return

module.exports = etl
