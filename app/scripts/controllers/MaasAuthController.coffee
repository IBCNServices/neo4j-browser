###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'MaasAuthCtrl', [
    '$scope'
    'MaasAuthService'
    'ConnectionStatusService'
    'Frame'
    'Settings'
    '$timeout'
    ($scope, AuthService, ConnectionStatusService, Frame, Settings, $timeout) ->
      $scope.username = ''
      $scope.password = ''
      $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
      $scope.static_user = $scope.connection_summary.user
      $scope.static_is_authenticated = $scope.connection_summary.is_connected

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
        

  ]
