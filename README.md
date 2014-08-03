Bower ETL service
===

Integrates 3rd-party data with bower data.

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