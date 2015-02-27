# vendor

moment = require 'moment'
Promise = require 'bluebird'
url = require 'url'
RegistryClient = require 'bower-registry-client'
registry = Promise.promisifyAll new RegistryClient
Octokit = require 'octokit'

# Custom
mapping = require 'githubMapping'

# ==========

noData =
  bowerRegistry: []
  github: []

# ==========
if process.env.NODE_ENV is 'development'
  _token = process.env.GITHUB_OAUTH_TOKEN_DEVELOPMENT
else
  _token = process.env.GITHUB_OAUTH_TOKEN_PRODUCTION
console.error "[ERROR] GITHUB_OAUTH_TOKEN_BOWER env var not set" if !_token

_gh = new Octokit.new {token: _token}

# get github repo info from bower register
# raw data @ http://bower.herokuapp.com/packages
getRepoName = (pkgName) ->
  if mapping.hasOwnProperty pkgName
    Promise.resolve ownerName: mapping[pkgName].split('/')[0], repoName: mapping[pkgName].split('/')[1]
  else
    registry.lookupAsync pkgName
      .then (entry) ->
        urlParsed = url.parse(entry.url).pathname.split '/'
        ownerName: urlParsed[1]
        repoName: urlParsed[2].replace '.git', ''
      .catch (err) ->
        noData.bowerRegistry.push pkgName
        throw new Error "Bower registry entry not found & no manual mapping for [#{pkgName}]."
        # rethrow so subsequent steps aren't processed
        return

# pkg obj passed from GA module
appendData = (pkg) ->
  append = (data) ->
    if !data.owner
      console.log data
    else
      pkg.ghOwner = data.owner.login
      pkg.ghOwnerAvatar = data.owner.avatar_url
      pkg.ghUrl = data.html_url
      pkg.ghDesc = data.description
      pkg.ghStars = data.stargazers_count
      pkg.ghIssues = data.open_issues_count
      pkg.ghUpdated = data.pushed_at
      pkg.ghUpdatedHuman = moment(data.pushed_at).fromNow()
      pkg.ghUpdatedHuman = pkg.ghUpdatedHuman.slice 0, pkg.ghUpdatedHuman.lastIndexOf ' '
      # trim ' ago' to ensure as short as possible
    return

  getRepoName pkg.name
    .then ((data) -> _gh.getRepo data.ownerName, data.repoName), null
    .then ((repo) -> repo.getInfo()), null
    .then append, null
    .catch (err) ->
      if err.message? and err.message.indexOf('Bower registry entry not found') isnt -1
        console.error err
      else
        noData.github.push pkg.name
        console.error new Error "Can't fetching Github data for #{ pkg.name } via API, err = #{err}"
      return

# log GH rate limit warning at certain intervals
listener = (rateLimitRemaining, rateLimit, method, path, data, raw, isBase64) ->
  log = (type) ->
    console[type] "[#{ type.toUpperCase() }] Github API rate limit has #{ rateLimitRemaining } of #{ rateLimit } remaining."
    return
  switch
    when rateLimitRemaining >= 1000 and rateLimitRemaining % 1000 is 0 then log 'info'
    when rateLimitRemaining is 500 or rateLimitRemaining is 100 then log 'warn'
  return
_gh.onRateLimitChanged listener

module.exports =
  appendData: appendData
  noData: noData
