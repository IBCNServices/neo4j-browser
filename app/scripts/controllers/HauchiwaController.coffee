###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64) ->

    $scope.status = "init"
    $scope.frame.resetError()
    $scope.autoRefresh = false

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      console.log("WOLOLOO")
      console.log(resp)
      $scope.hauchiwa = resp.hauchiwa
      $scope.data = resp.data
      $scope.location = resp.location
      if $scope.location == "sojobo"
        $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/" + $scope.hauchiwa
        console.log($scope.sojobo_url)
        lookForHauchiwa(resp.data)
      else if $scope.location == "local"
        $scope.status = "bundle-check"
        $scope.hauchiwa_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/"
        $scope.bundle = resp.data
      else if $scope.location.startsWith("http")
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
            hauchiwa_models = resp.data.models
            $scope.hauchiwa_url = $scope.location + "/" + hauchiwa_models[0] + "/"
            refreshBundle()
          else
            $scope.frame.setError "Could not determine how to reach the Hauchiwa."
            console.log("Could not determine how to reach the Hauchiwa: " + $scope.location)

    lookForHauchiwa = (data) ->
      if data["service-status"].current == "error"
        $scope.status = "error"
        $scope.frame.setError data["service-status"].message
      else if data["service-status"].current == "active"
        message = data["service-status"].message
        pfPattern = /^Ready pf:"(?:.*->[0-9]* )*(.*)->5000.*"/
        hauchiwa_ipPort = message.replace(pfPattern, '$1')
        if hauchiwa_ipPort.length != message.length
          $scope.status = "bundle-check"
          $scope.hauchiwa_url = "http://" + hauchiwa_ipPort + "/"
          refreshBundle()
        else
          console.log("Message '" + message + "' does not contain the correct portforwarding.")
      else
        console.log("'service-status' not 'active' yet.")

    refreshHauchiwa = () ->
      if $scope.status != "error" and $scope.status != "bundle-check"
        req = {
          "method"  : "GET"
          "url"     : $scope.sojobo_url
        }

        $http(req).then(
          (response) ->
            lookForHauchiwa(response.data)
          , (r) ->
            console.log("Could not connect to the Sojobo: "+Settings.endpoint.tengu+"/"+$scope.hauchiwa)
            $scope.frame.setError "Could not connect to the Sojobo."
        )
      else
        console.log("'refreshHauchiwa' called again!? [status: "+$scope.status+"]")

    refreshBundle = () ->
      $scope.frame.resetError()
      if $scope.status == "bundle-check"
        req = {
          "method"  : "GET"
          #"url"     : "http://localhost:9000/content/bundles/iot_get_status.json"
          "url"     : $scope.hauchiwa_url
        }

        $http(req).then(
          (response) ->
            if $scope.hauchiwa == "unknown"
              console.log("Hauchiwa name not yet set")
              $scope.hauchiwa = response.data.environment
            $scope.bundle = response.data
          , (r) ->
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

      if $scope.autoRefresh and !$scope.frame.isTerminating
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
