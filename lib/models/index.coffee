# vendor
fs = require 'fs'
p = require 'path'
Sequelize = require 'sequelize'
_ = require 'lodash-node'

# custom

# ==========

# init db
client = new Sequelize config.db.database, config.db.username, config.db.password, {
  host: config.db.host
  port: config.db.port
  dialect: config.db.dialect
  omitNull: true
  native: true # enable ssl w/ pg
  logging: false
}

# load models
models = {}

fs
  .readdirSync __dirname
  .filter (fileName) ->
    fileName.match(/.+\.coffee/g) isnt null && fileName isnt 'index.coffee'
  .forEach (fileName) ->
    model = client.import p.join __dirname, fileName
    models[model.name] = model
    return

# set up associations if models have any
Object.keys(models).forEach (modelName) ->
  models[modelName].associate(models) if models[modelName].hasOwnProperty 'associate'
  return

# ==========

module.exports = _.assign {client: client}, models
