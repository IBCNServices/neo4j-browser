###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'BundleController', [
    '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'Frame'
  ($scope, Settings, ConnectionStatusService, $http, $timeout, $base64, Frame) ->

    console.log("use sojobo? "+Settings.useSojobo)

    $scope.new_hauchiwa = ''
    $scope.ssh_key = ''
    $scope.bundle_name = '';
    $scope.bundle = ''
    $scope.status = "init"

    $scope.frame.resetError()
    $scope.static_user = ConnectionStatusService.connectedAsUser()
    $scope.static_is_authenticated = ConnectionStatusService.isConnected()
    $scope.certificate = ConnectionStatusService.plainConnectionAuthData()[1]

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.bundle_name = resp.bundle_name
      $scope.bundle = resp.bundle

    $scope.sojobo_url

    $scope.checkStatus = () ->
      Frame.create {input: "#{Settings.cmdchar}tengu hauchiwa #{$scope.new_hauchiwa}"}

    $scope.deployBundle = ->
      is_authenticated = ConnectionStatusService.isConnected()
      $scope.frame.resetError()

      if not $scope.new_hauchiwa.length
        $scope.frame.addErrorText 'You have to enter a name for the Hauchiwa. '
      if not $scope.bundle_name.length
        $scope.frame.addErrorText 'The bundle description is still not loaded. '
      return if $scope.frame.getDetailedErrorText().length

      if Settings.useSojobo
        $scope.sojobo_url = Settings.endpoint.tengu+"/hauchiwa/"+$scope.new_hauchiwa
        #bundle = $scope.bundle.replace(/hhh-/g, "")
      else
        $scope.sojobo_url = Settings.endpoint.tengu+"/bundle"
        #bundle = $scope.bundle.replace(/hhh/g, $scope.new_hauchiwa.toLowerCase())

      console.log(bundle)

      req = {
        "method"  : "PUT"
        "url"     : $scope.sojobo_url
        "headers" : { "Content-Type" : "application/json", "emulab-s4-cert" : $scope.certificate }
        "data"    : { "ssh-keys" : $scope.ssh_key, "bundle" : $base64.encode(bundle) }
      }

      $http(req).then(
        (response) ->
          $scope.status = "creating"
          $scope.frame.resetError()
          $scope.focusEditor()
        , (r) ->
          $scope.frame.setError r
      )

]