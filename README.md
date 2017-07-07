to run:

* install crystal
* set `BOSH_ENVIRONMENT`, `BOSH_CLIENT`, `BOSH_SECRET` env vars
* set `DEPLOYMENT_NAME` env var to the deployment you want to watch
* `crystal dep` (to get deps)
* `crystal run src/bosh-visualizer.cr` to start local server
