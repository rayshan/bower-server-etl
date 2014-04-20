# vendor

Octokit = require 'octokit'
moment = require 'moment'
rsvp = require "rsvp"
url = require 'url'
RegistryClient = require 'bower-registry-client'
registry = new RegistryClient

# Custom

# ==========

pkg =
  "name": "jquery"
  "rank":
    "current": 1
    "prior": 1
  "users":
    "current": 9043
    "prior": 8714
  "pkgs":
    "current": 18673
    "prior": 18286

_token = process.env.GITHUB_OAUTH_TOKEN_BOWER
console.error "ERROR: GITHUB_OAUTH_TOKEN_BOWER env var not set" if !_token?
_gh = new Octokit.new {token: _token}

# get github repo info from bower register
getRepoNames = (pkgName) ->
  new rsvp.Promise (resolve, reject) ->
    registry.lookup pkgName, (err, entry) ->
      if err
        console.error "ERROR: registry entry not found given pkgName #{pkgName}, err = ", err
        reject err
      else
        # entry.url = git://github.com/jquery/jquery.git
        urlParsed = url.parse(entry.url).pathname.split '/'
        ownerName = urlParsed[urlParsed.length - 2]
        repoName = urlParsed[urlParsed.length - 1].split('.')[0]
        resolve _gh.getRepo ownerName, repoName
      return

appendData = (pkg) ->
  getRepoNames(pkg.bName).then (repo) ->
    repo.getInfo().then (data) ->
      pkg.ghFullName = data.full_name
      pkg.ghUrl = data.html_url
      pkg.ghDesc = data.description
      pkg.ghStars = data.stargazers_count
      pkg.ghForks = data.forks_count
      pkg.ghIssues = data.open_issues_count
      pkg.ghUpdated = data.pushed_at
      pkg.ghUpdatedHuman = moment(data.pushed_at).fromNow()
      return

module.exports =
  appendData: appendData