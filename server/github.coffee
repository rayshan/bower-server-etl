# vendor

Octokit = require 'octokit'
moment = require 'moment'
Promise = require 'bluebird'
url = require 'url'
RegistryClient = require 'bower-registry-client'
registry = Promise.promisifyAll new RegistryClient

# Custom

# ==========

# TODO
mapping =
  'angular': ['angular', 'angular.js']
  'bootstrap-sass': ['twbs', 'bootstrap']
  'requirejs': ['jrburke', 'requirejs']

_token = process.env.GITHUB_OAUTH_TOKEN_BOWER
console.error "[ERROR] GITHUB_OAUTH_TOKEN_BOWER env var not set" if !_token?
_gh = new Octokit.new {token: _token}

# get github repo info from bower register
# raw data @ http://bower.herokuapp.com/packages
getRepoName = (pkgName) ->
  if mapping.hasOwnProperty pkgName
    new Promise (resolve) ->
      resolve ownerName: mapping[pkgName][0], repoName: mapping[pkgName][1]
      return
  else
    registry.lookupAsync pkgName
      .then (entry) ->
        urlParsed = url.parse(entry.url).pathname.split '/'
        ownerName = urlParsed[urlParsed.length - 2]
        repoName = urlParsed[urlParsed.length - 1].split('.')[0]

        ownerName: ownerName
        repoName: repoName
      .catch (err) ->
        throw new Error "[ERROR] registry entry not found given pkgName #{pkgName}, err = #{ err }"
        return

getRepoData = (data) -> _gh.getRepo data.ownerName, data.repoName

# pkg obj passed from GA module
appendData = (pkg) ->
  append = (data) ->
    pkg.ghOwner = data.owner.login
    pkg.ghOwnerAvatar = data.owner.avatar_url
    pkg.ghUrl = data.html_url
    pkg.ghDesc = data.description
    pkg.ghStars = data.stargazers_count
    pkg.ghIssues = data.open_issues_count
    pkg.ghUpdated = data.pushed_at
    pkg.ghUpdatedHuman = moment(data.pushed_at).fromNow()
    pkg.ghUpdatedHuman = pkg.ghUpdatedHuman.slice 0, pkg.ghUpdatedHuman.lastIndexOf ' '
    return

  getRepoName pkg.bName
    .then getRepoData
    .then (repo) -> repo.getInfo()
    .then append
    .catch (err) ->
      console.error err
      # throw Error "[ERROR] github data not found for bower pkg #{ pkg.bName } or api error, msg = #{ err.error.message }"
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