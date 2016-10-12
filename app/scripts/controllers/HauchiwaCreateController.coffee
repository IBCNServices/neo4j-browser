###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaCreateController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'Frame', 'CurrentUser'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64, Frame, CurrentUser) ->
    $scope.newHauchiwa = ''
    $scope.ssh_key = ''
    $scope.bundle = ''
    $scope.modelName = ''
    
    $scope.status = "start"
    $scope.ssh_key_pattern = /^ssh-rsa [A-Za-z0-9+]+ \w+@\w+/

    $scope.frame.resetError()
    $scope.static_user = ConnectionStatusService.connectedAsUser()
    $scope.static_is_authenticated = ConnectionStatusService.isConnected()
    $scope.certificate = ConnectionStatusService.plainConnectionAuthData()[1]

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.bundle = resp.bundle
      $scope.modelName = resp.modelName
      if resp.hauchiwaName != "blank"
        $scope.newHauchiwa = resp.hauchiwaName
      $scope.createHauchiwa()

    $scope.checkStatus = () ->
      Frame.create {input: "#{Settings.cmdchar}tengu hauchiwa status #{$scope.newHauchiwa}"}

    $scope.createHauchiwa = ->
      $scope.status = "initializing"
      $scope.frame.resetError()

      if not $scope.newHauchiwa? || not $scope.newHauchiwa.length
        $scope.frame.addErrorText 'You have to enter a name for the Hauchiwa. '
        $scope.status = "start"
      if not $scope.bundle
        $scope.frame.addErrorText 'The bundle description is still not loaded. '
        $scope.status = "start"
      if $scope.ssh_key && not $scope.ssh_key_pattern.test($scope.ssh_key)
        $scope.frame.addErrorText 'The SSH key field does not have the correct format. '
        $scope.status = "start"
      return if $scope.frame.getDetailedErrorText().length

      $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/"
      
      $scope.bundle.services["h-"+$scope.newHauchiwa] = $scope.bundle.services['{{servicename}}']
      delete $scope.bundle.services['{{servicename}}']
      $scope.bundle.relations.forEach(
        (relation, i) -> 
          j = relation.indexOf('{{servicename}}')
          if j >= 0
            relation.splice(j, 1, "h-"+$scope.newHauchiwa)
      )

      if $scope.ssh_key
        $scope.bundle.services["h-"+$scope.newHauchiwa].options['ssh-keys'] = $scope.bundle.services["h-"+$scope.newHauchiwa].options['ssh-keys'].replace(/{{sshkeys}}/g, "," + $scope.ssh_key)
      else
        $scope.bundle.services["h-"+$scope.newHauchiwa].options['ssh-keys'] = $scope.bundle.services["h-"+$scope.newHauchiwa].options['ssh-keys'].replace(/{{sshkeys}}/g, "")
        
      $scope.bundle.services["h-"+$scope.newHauchiwa].options['emulab-s4-cert'] = $scope.certificate
      
      $scope.bundle.services["h-"+$scope.newHauchiwa].options['feature-flags'] = Settings.featureflags

      console.log($scope.modelName?)

      if $scope.modelName?
        # create hauchiwa with model
        console.log(CurrentUser.getToken('token'))
        if $scope.modelName.startsWith('http://')
          model_url = $scope.modelName
          mapping_url = null
        else
          model_url = Settings.endpoint.bundles.replace(/{{bundlename}}/g, $scope.modelName)
          mapping_url = Settings.endpoint.mappings.replace(/{{bundlename}}/g, $scope.modelName)
        console.log(model_url)
        req = {
          "method"  : "GET"
          "url"     : model_url
          "headers" :
            "Accept" : "plain/text"
        }
        # TODO: make these requests parallel $q.all(...)
        $http(req).then(
          (response) ->
            bundle = response.data  
            if mapping_url?
              req = {
                "method"  : "GET"
                "url"     : mapping_url
                "headers" :
                  "Accept" : "plain/text"
              }

              $http(req).then(
                (response) ->
                  # add mapping to modelinfo servicename
                  bundle.services.modelinfo.options =
                    mapping : JSON.stringify(response.data)
                  console.log(bundle)
                  $scope.frame.resetError()
                  $scope.focusEditor()
                  deployHauchiwa(bundle)
                , (r) ->
                  # no mapping found
                  console.log("No mapping information found on url [" + mapping_url + "]. Continue without mapping info.")
                  $scope.frame.resetError()
                  $scope.focusEditor()
                  deployHauchiwa(bundle)
              )
            else
              console.log("No need to retrieve mapping info, bundle was provided by user.")
              $scope.frame.resetError()
              $scope.focusEditor()
              deployHauchiwa(bundle)
          , (r) ->
            console.log(r)
            $scope.status = "start"
            $scope.frame.setError "There was an error in creating the Hauchiwa. Could not get the model info [" + model_url + "]."
        )
      else
        # only create the hauchiwa
        $scope.bundle.services["h-"+$scope.newHauchiwa].options['bundle'] = ""
        deployHauchiwa()
      
    deployHauchiwa = (bundle) ->
      if bundle?
        $scope.bundle.services["h-"+$scope.newHauchiwa].options['bundle'] = $base64.encode(JSON.stringify(bundle))
      console.log($scope.bundle)
      
      req = {
        "method"  : "PUT"
        "url"     : $scope.sojobo_url
        "headers" : { 
          "Content-Type" : "text/plain"
          "id-token"     : CurrentUser.getToken('data_token')
        }
        "data"    : $scope.bundle
      }

      $http(req).then(
        (response) ->
          $scope.status = "creating"
          $scope.frame.resetError()
          $scope.focusEditor()
        , (r) ->
          console.log(r)
          $scope.status = "start"
          $scope.frame.setError "There was an error in creating the Hauchiwa."
      )

]
