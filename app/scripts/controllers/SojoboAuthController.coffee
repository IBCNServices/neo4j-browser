###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'SojoboAuthCtrl', [
    '$scope'
    'SojoboAuthService'
    'ConnectionStatusService'
    'Frame'
    'Settings'
    '$http'
    '$timeout'
    ($scope, AuthService, ConnectionStatusService, Frame, Settings, $http, $timeout) ->
      $scope.username = ''
      $scope.password = ''
      $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
      $scope.static_user = $scope.connection_summary.user
      $scope.static_is_authenticated = $scope.connection_summary.is_connected

      $scope.$watch 'frame.response', (resp) ->
        return unless resp
        if resp.userinfo?
          $scope.user_info = resp.userinfo
          $scope.models = []
          for ctrl in $scope.user_info.controllers
            console.log ctrl
            if ctrl.models?
              for model in ctrl.models
                console.log model
                $scope.models.push {
                  name       : model.name
                  controller : ctrl.name
                  access     : model.access
                  type       : ctrl.type
                }

      $scope.signin = () ->
        if not $scope.username? || not $scope.username.length
          $scope.frame.addErrorText 'You have to enter a username to sign in. '
        if not $scope.password? || not $scope.password.length
          $scope.frame.addErrorText 'You have to enter a password. We do not check the password strength.'
        return if $scope.frame.getDetailedErrorText().length

        AuthService.authenticate($scope.username, $scope.password)

        $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
        $scope.static_user = $scope.connection_summary.user
        $scope.static_is_authenticated = $scope.connection_summary.is_connected
        $scope.frame.resetError()


        Frame.createOne({input:"#{Settings.initCmd}"})
        $scope.focusEditor()

      $scope.changePassword = () ->
        if not $scope.password? || not $scope.password.length
          $scope.frame.addErrorText 'You have to enter a password. We do not check the password strength.'
        return if $scope.frame.getDetailedErrorText().length

        url = Settings.endpoint.tengu + "/users/" + $scope.static_user
        basicAuth = ConnectionStatusService.plainConnectionAuthData()[1]

        req = {
          "method"  : "PUT"
          "url"     : url
          "headers"  : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          }
          "data"    : {
            "password"    : $scope.password
          }
        }

        $http(req).then(
          (response) ->
            AuthService.authenticate($scope.static_user, $scope.password)
            $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
            $scope.static_is_authenticated = $scope.connection_summary.is_connected
            $scope.frame.resetError()
          , (r) ->
            console.log(r)
            $scope.frame.setError "There was an error in creating the Model: " + r.data
        )

  ]
