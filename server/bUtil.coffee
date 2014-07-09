# util is node core module, hense bUtil.coffee

# remove leading & trailing /
util = {}

util.removeSlash = (input) -> input.replace /\//g, ''

util.etlLogger = (step, modelName) ->
  console.info "[INFO] ETL - #{step}ing [#{modelName}] data."
  return

module.exports = util