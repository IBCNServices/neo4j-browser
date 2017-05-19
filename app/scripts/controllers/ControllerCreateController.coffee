###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ControllerCreateController', [
    '$scope', 'Settings', '$http', '$timeout', '$base64', 'Frame', 'CurrentUser', '$rootScope'
  ($scope, Settings, $http, $timeout, $base64, Frame, CurrentUser, $rootScope) ->
    $scope.frame.resetError()
    $scope.controller = null

    $scope.setActive = (tab) ->
      $rootScope.stickyTab = $scope.tab = tab

    $scope.isActive = (tab) ->
      tab is $scope.tab

    $scope.isAvailable = (tab) ->
      tab in $scope.availableModes

    $scope.availableModes = ['aws', 'google']
    $scope.setActive('aws')

    $scope.status = "start"
    $scope.is_authenticated = CurrentUser.isAuthenticated()

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      if $scope.frame.hasErrors
        $scope.status = "start"
      else
        $scope.controller = resp.controller
        $scope.createController()

    $scope.createController = (type) ->
      console.log(type)
      $scope.status = "creating.controller"
      $scope.frame.resetError()

      if not $scope.controller? || not $scope.controller.length
        $scope.frame.addErrorText 'You have to provide a name for the new Environment. '
      if not $scope.region? || not $scope.region.length
        $scope.frame.addErrorText 'You have to the region where you want to create your Environment. '
      if type == "google"
        if not $scope.credentials? || not $scope.credentials.length
          $scope.frame.addErrorText 'Please Copy-Paste your Google credentials. '
        else
          try
            credentials_json = JSON.parse($scope.credentials)
            console.log credentials_json
            $scope.availableModes = ['google']
            $scope.setActive('google')
          catch error
            $scope.frame.addErrorText 'There was a syntax error in the credentials you provided: ' + error + '. '
      else if type == "aws"
        if not $scope.access_key? || not $scope.access_key.length
          $scope.frame.addErrorText 'Please give the AWS Access Key. '
        if not $scope.secret_key? || not $scope.secret_key.length
          $scope.frame.addErrorText 'Please give the AWS Secret Key. '
        credentials_json = {
          "access-key" : $scope.access_key
          "secret-key" : $scope.secret_key
        }
        $scope.availableModes = ['aws']
        $scope.setActive('aws')


      if $scope.frame.getDetailedErrorText().length
        $scope.status = "start"
        return
      else
        static_user = CurrentUser.getToken('profile').name
        basicAuth = CurrentUser.getToken('token')

        req = {
          "method"  : "POST"
          "url"     : Settings.endpoint.tengu + "/tengu/controllers"
          "headers" :
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          "data" : {
            "controller"  : $scope.controller
            "type"        : type
            "region"      : $scope.region
            "credentials" : credentials_json
          }
        }

        console.log req

        $http(req).then(
          (response) ->
            $scope.status = "finished"
            $scope.availableModes = ['creating']
            $scope.setActive('creating')
            $scope.focusEditor()
            $scope.frame.resetError()
          , (r) ->
            console.log(r)
            $scope.status = "start"
            $scope.frame.setError "There was an error in creating the Environment: " + r.data
        )

]
