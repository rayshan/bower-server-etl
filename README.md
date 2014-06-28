[stats.bower.io](http://stats.bower.io)
===

Insights into Bower, the best package manager for the web.

v1 planning here:
https://github.com/bower/bower/issues/1164#issuecomment-38207751

v2 & beyond planning done in this repo's issues.

## Development

System Dependencies
- Node.js
- Redis
- [foreman](https://github.com/ddollar/foreman) (due to deploy target being Heroku)

Please ask repo owners for foreman's `.env` file containing API keys

Install back-end dependencies: `npm install`

Install front-end dependencies: `bower install`

Compile assets & start dev server, with live-watch: `gulp`

View app @ `localhost:3000`

## Contribution

Due to package owners using Bower-specific GitHub repos, e.g. https://github.com/angular/bower-angular, GitHub stats sometimes look funny. Please submit a PR for [`githubMapping.coffee`](server/githubMapping.coffee) if you discover one.

## Deployment

Current deployment target is Heroku. Data is all cached in Redis via Redis Labs. Also tested on DigitalOcean VPS.

Server time zone: `America/Los_Angeles` (API returned times are RFC2616 UTC)