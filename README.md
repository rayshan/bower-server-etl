[stats.bower.io](http://stats.bower.io)
===

Insights into Bower, the best package manager for the web.

v1 planning here:
https://github.com/bower/bower/issues/1164#issuecomment-38207751

v2 & beyond planning done in this repo's issues.

## Deployment

**WIP**

Current deployment target is Heroku. Data is all cached in Redis via Redis Labs. Also tested on DigitalOcean VPS.

Server time zone: `America/Los_Angeles`

- Node.js
- Redis
- Google OAuth 2.0 [service account](https://developers.google.com/accounts/docs/OAuth2ServiceAccount) private key (contact repo owner)
- Github API key (create your own)
- ...

`git clone`
`npm test`
`gulp dev`

## Contribution

Due to package owners using Bower-specific GitHub repos, e.g. https://github.com/angular/bower-angular, GitHub stats sometimes look funny. Please submit a PR for `githubMapping.coffee` if you discover one.