###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaCreateController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'Frame'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64, Frame) ->
    $scope.new_hauchiwa = ''
    $scope.ssh_key = ''
    $scope.bundle = ''
    
    $scope.status = "start"

    $scope.frame.resetError()
    $scope.static_user = ConnectionStatusService.connectedAsUser()
    $scope.static_is_authenticated = ConnectionStatusService.isConnected()
    $scope.certificate = ConnectionStatusService.plainConnectionAuthData()[1]

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.bundle = resp.bundle
      if resp.hauchiwaName != "blank"
        $scope.new_hauchiwa = resp.hauchiwaName
        $scope.deployBundle()

    $scope.checkStatus = () ->
      Frame.create {input: "#{Settings.cmdchar}tengu hauchiwa status #{$scope.new_hauchiwa}"}

    $scope.createHauchiwa = ->
      $scope.status = "initializing"
      $scope.frame.resetError()

      if not $scope.new_hauchiwa.length
        $scope.frame.addErrorText 'You have to enter a name for the Hauchiwa. '
      if not $scope.bundle.length
        $scope.frame.addErrorText 'The bundle description is still not loaded. '
      return if $scope.frame.getDetailedErrorText().length

      $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0]
      
      $scope.bundle = $scope.bundle.replace(/{{servicename}}/g, "h-" + $scope.new_hauchiwa)
      
      if $scope.ssh_key
        $scope.bundle = $scope.bundle.replace(/{{sshkeys}}/g, "," + $scope.ssh_key)
      else
        $scope.bundle = $scope.bundle.replace(/{{sshkeys}}/g, "")
        
      $scope.bundle = $scope.bundle.replace(/{{s4cert}}/g, $scope.certificate)
      
      if $scope.model?
        $scope.bundle = $scope.bundle.replace(/{{bundle}}/g, $base64.encode($scope.model))
      else
        $scope.bundle = $scope.bundle.replace(/{{bundle}}/g, "")

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
