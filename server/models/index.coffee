# load all files under models dir

modelRegistry = []

override = # ['geo.coffee']

modelFiles = if override then override else require('fs').readdirSync __dirname

modelFiles.forEach (fileName) ->
  if fileName.match(/.+\.coffee/g) isnt null && fileName isnt 'index.coffee'
    name = fileName.replace '.coffee', ''
    modelRegistry.push name

    module.exports[name] = require './' + fileName
  return

console.info "modelRegistry = #{modelRegistry}"

module.exports.modelRegistry = modelRegistry