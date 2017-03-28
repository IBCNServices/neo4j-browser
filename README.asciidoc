# Tengu Browser

Tengu browser is a UI to create and manage Sojobo's and Hauchiwa's.

## Development

**Set up your environment**

  * Install [NodeJs](https://nodejs.org/)
  * run `npm install` in this directory. *This installs npm modules needed to build the browser code.*
  * run `npm install -g grunt-cli`. *This puts the grunt command on your path.*

**Run in development mode**

Run `grunt server` in this directory. *This listens on **port 9000**. Any local changes to the browser code will be applied immediatley by reloading the page.*


## Current list of commands

### Tengu specific
  
  * `:tengu user-info`: list of deployed models visible by the current user.
  * `:tengu model create`: create empty model
  * `:tengu model create --bundle {streaming|microbatch}`: create model with the predefined bundle already deployed
  * `:tengu model create --bundle {url}`: create model with the bundle (defined by the `url`) deployed. Make sure the endpoint has defined the `Access-control-allow-origin: *` header.
  * `:tengu model status {model}@{controller}`: show the status of the model `{model}` deployed on the controller `{controller}`
  * `:tengu model delete {model}@{controller}`: delete the model `{model}` deployed on the controller `{controller}`

### General

  * `:signin`: signs in the user
  * `:signout`: signs you out, and removing all local storage
  * `:config`: shows all the different parameters currently used by the UI
