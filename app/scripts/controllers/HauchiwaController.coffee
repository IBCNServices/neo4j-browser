###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'CurrentUser'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64, CurrentUser) ->

    $scope.hauchiwa = "unknown"
    $scope.status = "init"
    $scope.frame.resetError()
    $scope.autoRefresh = true

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      console.log(resp)
      if resp.location?
        $scope.hauchiwa = resp.hauchiwa
        $scope.data = resp.data
        $scope.location = resp.location
        if $scope.location == "sojobo"
          console.log("loc=sojobo")
          $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/h-" + $scope.hauchiwa
          lookForHauchiwa(resp.data)
        else if $scope.location == "local"
          console.log("loc=local")
          $scope.status = "bundle-check"
          $scope.hauchiwa_url = Settings.endpoint.tengu
          $scope.bundle = resp.data
          refreshLater()
        else if $scope.location.startsWith("http")
          console.log("loc=url")
          if resp.data.charm?
            $scope.sojobo_url = $scope.location
            lookForHauchiwa(resp.data)
          else
            $scope.status = "bundle-check"
            if resp.data.services?
              $scope.hauchiwa_url = $scope.location
              $scope.hauchiwa = resp.data.environment
              $scope.bundle = resp.data
            else if resp.data.name
              $scope.hauchiwa_models = resp.data.models
              $scope.hauchiwa_url = $scope.location + "/" + $scope.hauchiwa_models[0]
            else
              $scope.status = "error"
              $scope.frame.setError "Could not determine how to reach the Hauchiwa."
              console.log("Could not determine how to reach the Hauchiwa: " + $scope.location + ".")
            refreshLater()
      else
        $scope.status = "error"
        $scope.autoRefresh = no
        $scope.frame.setError resp

    lookForHauchiwa = (data) ->
      if data["service-status"]?
        if data["service-status"].current? and data["service-status"].current == "error"
          $scope.status = "error"
          $scope.frame.setError data["service-status"].message
        else if data["service-status"].current? and data["service-status"].current == "active"
          message = data["service-status"].message
          pfPattern = /^Ready pf:"(?:.*->[0-9]* )*(.*)->5000.*"/
          hauchiwa_ipPort = message.replace(pfPattern, '$1')
          if hauchiwa_ipPort.length != message.length
            $scope.status = "models-check"
            hauchiwa_rooturl = "http://" + hauchiwa_ipPort

            req = {
              "method"  : "GET"
              "url"     : hauchiwa_rooturl
              "header"  : {"id_token" : CurrentUser.getToken('data_token')}
            }

            $http(req).then(
              (response) ->
                if response.data? and response.data.models?
                  $scope.hauchiwa_models = response.data.models
                  if $scope.hauchiwa_models.length == 1
                    $scope.status = "bundle-check"
                    $scope.model =  $scope.hauchiwa_models[0]  
                    $scope.hauchiwa_url = hauchiwa_rooturl + "/" + $scope.model
                    console.log("Only one model present: " + $scope.hauchiwa_url)
                    refreshLater()
                  else if $scope.hauchiwa_models.length > 1
                    $scope.status = "model-choice"
                    $scope.hauchiwa_url = hauchiwa_rooturl
                    console.log("Multiple models available.")
                else if response.data? and response.data == "Welcome to Hauchiwa API v0.1"
                  $scope.status = "bundle-check"
                  $scope.hauchiwa_url = hauchiwa_rooturl + "/status"
                  console.log("The Hauchiwa still has the old version, using: "+$scope.hauchiwa_url)
                  refreshLater()
                else
                  $scope.status = "error"
                  $scope.frame.setError "Could not retrieve models from the Hauchiwa."
              , (r) ->
                $scope.status = "error"
                $scope.frame.setError "Could not retrieve models from the Hauchiwa."
            )

          else
            console.log("Message '" + message + "' does not contain the correct portforwarding.")
            refreshLater()
        else
          console.log("'service-status' not 'active' yet.")
          refreshLater()
          
    $scope.selectModel = () ->
      $scope.status = "bundle-check"  
      $scope.hauchiwa_url = $scope.hauchiwa_url + "/" + $scope.model
      console.log("User selected model["+$scope.model+"]: " + $scope.hauchiwa_url)
      refreshLater()

    refreshHauchiwa = () ->
      if $scope.status != "error" and $scope.status != "bundle-check"
        req = {
          "method"  : "GET"
          "url"     : $scope.sojobo_url
          "header"  : {"id_token" : CurrentUser.getToken('data_token')}
        }

        $http(req).then(
          (response) ->
            lookForHauchiwa(response.data)
          , (r) ->
            $scope.status = "error"
            console.log("Could not connect to the Sojobo: " + Settings.endpoint.tengu + "/" + $scope.hauchiwa)
            $scope.frame.setError "Could not connect to the Sojobo."
        )
      else
        console.log("'refreshHauchiwa' called again!? [status: "+$scope.status+"]")

    refreshBundle = () ->
      $scope.frame.resetError()
      if $scope.status == "bundle-check"
        req = {
          "method"  : "GET"
          "url"     : $scope.hauchiwa_url
          "header"  : {"id_token" : CurrentUser.getToken('data_token')}
        }
        $http(req).then(
          (response) ->
            if $scope.hauchiwa == "unknown"
              console.log("Hauchiwa name not yet set")
              $scope.hauchiwa = response.data.environment
            $scope.bundle = response.data
          , (r) ->
            $scope.status = "error"
            $scope.frame.setError "Could not retrieve the status information of the Hauchiwa."
        )

    $scope.refresh = () ->
      if $scope.status == "bundle-check"
        refreshBundle()
      else
        refreshHauchiwa()

    timer = null
    refreshLater = () =>
      $timeout.cancel(timer)
      if $scope.status == "error"
        $scope.autoRefresh = no
      else if $scope.autoRefresh and !$scope.frame.isTerminating
        $scope.refresh()
        timer = $timeout(
          refreshLater
          ,
          (Settings.refreshInterval * 1000)
        )

    $scope.toggleAutoRefresh = () ->
      $scope.autoRefresh = !$scope.autoRefresh
      refreshLater()

]
