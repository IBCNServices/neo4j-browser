###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaCreateController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'Frame'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64, Frame) ->
    $scope.newHauchiwa = ''
    $scope.ssh_key = ''
    $scope.bundle = ''
    $scope.modelName = ''
    
    $scope.status = "start"

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

      if not $scope.newHauchiwa.length
        $scope.frame.addErrorText 'You have to enter a name for the Hauchiwa. '
      if not $scope.bundle.length
        $scope.frame.addErrorText 'The bundle description is still not loaded. '
      return if $scope.frame.getDetailedErrorText().length

      $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/"
      
      $scope.bundle = $scope.bundle.replace(/{{servicename}}/g, "h-" + $scope.newHauchiwa)
      
      if $scope.ssh_key
        $scope.bundle = $scope.bundle.replace(/{{sshkeys}}/g, "," + $scope.ssh_key)
      else
        $scope.bundle = $scope.bundle.replace(/{{sshkeys}}/g, "")
        
      $scope.bundle = $scope.bundle.replace(/{{s4cert}}/g, $scope.certificate)
      
      if $scope.modelName
        req = {
          "method"  : "GET"
          "url"     : "#{Settings.endpoint.bundles}/#{$scope.modelName}.yaml"
          "headers" :
            "Accept" : "plain/text"
        }

        $http(req).then(
          (response) ->
            $scope.bundle = $scope.bundle.replace(/{{bundle}}/g, $base64.encode(response.data))
            $scope.frame.resetError()
            $scope.focusEditor()
            deployHauchiwa()
          , (r) ->
            console.log(r)
            $scope.status = "start"
            $scope.frame.setError "There was an error in creating the Hauchiwa."
        )
      else
        $scope.bundle = $scope.bundle.replace(/{{bundle}}/g, "")
        deployHauchiwa()
      
    deployHauchiwa = ->
      console.log($scope.bundle)
      
      req = {
        "method"  : "PUT"
        "url"     : $scope.sojobo_url
        "headers" : { "Content-Type" : "text/plain"}
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
