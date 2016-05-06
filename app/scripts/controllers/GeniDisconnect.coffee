###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'GeniDisconnectCtrl', [
    '$scope'
    'GeniAuthService'
    'ConnectionStatusService'
    ($scope, GeniAuthService, ConnectionStatusService) ->
      GeniAuthService.forget()
      $scope.static_user = ConnectionStatusService.connectedAsUser()
      $scope.static_is_authenticated = ConnectionStatusService.isConnected()

      $scope.focusEditor()
  ]
