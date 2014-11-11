Bower ETL service
===

Integrates 3rd-party data with bower data.

## Development

System Dependencies
- Node.js
- Redis
- [foreman](https://github.com/ddollar/foreman) (due to deploy target being Heroku)

Please ask repo owners for foreman's `.env` file containing API keys

Install dependencies - `npm install`

Ensure tests pass - `npm test`

Spin up Postgres instance

Run Sequelize migrations, e.g. `seq db:migrate`

Run API service - `gulp`

## Contribution

Issues should be submitted to [`bower-server-registry` repo](https://github.com/bower/registry).

Due to package owners using Bower-specific GitHub repos, e.g. https://github.com/angular/bower-angular, GitHub stats sometimes look funny. Please submit a PR for [`githubMapping.coffee`](server/githubMapping.coffee) if you discover one.

## Deployment

Current deployment target is Heroku. Data is all cached in Redis via Redis Labs. Also tested on DigitalOcean VPS.

API service time zone: UTC
