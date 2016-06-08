###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'GoogleConnectionController', [
    '$scope'
    'ConnectionStatusService'
    'Frame'
    'Settings'
    'GAuth2'
    'CurrentUser'
    '$timeout'
    '$window'
    ($scope, ConnectionStatusService, Frame, Settings, GAuth2, CurrentUser, $timeout, $window) ->
      $scope.user = null
        
      $scope.$watch 'frame.response', (success) ->
        if success
          $scope.onSignIn()
        else if success != null
          $window.gapi.signin2.render('signin', { 
            onsuccess : $scope.onSignIn
          })
        
      $scope.onSignIn = (googleUser) ->
        CurrentUser.login().then((res) -> $scope.user = res)
     
  ]
