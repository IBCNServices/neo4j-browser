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
    '$timeout'
    '$window'
    ($scope, ConnectionStatusService, Frame, Settings, GAuth2, $timeout, $window) ->
      $scope.username = 'localuser'
      $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
      $scope.static_user = $scope.connection_summary.user

      complete = (cert) ->
        GeniAuthService.authenticate(cert)
        $scope.frame.resetError()
        $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
        $scope.static_user = $scope.connection_summary.user
        $scope.static_is_authenticated = $scope.connection_summary.is_connected
        setPolicyMessage()
        Frame.create({input:"#{Settings.initCmd}"})
        $scope.focusEditor()

      $scope.authenticate = (event) ->
        $scope.frame.resetError()
        genilib.authorize(myId, myCert, complete)
        return false;
        
      onSignIn = () ->
        googleUser = $scope.auth2.currentUser.get()
        console.log(googleUser)
        
      onSignOut = () ->
        console.log("signout")
        
      updateSignIn = () ->
        console.log('update sign in state')
        $scope.signed_in = $scope.auth2.isSignedIn.get()
        if ($scope.signed_in)
          console.log('signed in')
          onSignIn()
        else
          console.log('signed out')
          onSignOut()
      
      GAuth2.get().then( (auth2) ->
        console.log("test GCC")
        $scope.auth2 = auth2
        #$window.gapi.auth2.getAuthInstance()
        $scope.auth2.isSignedIn.listen(updateSignIn);
        $scope.auth2.then(updateSignIn);
      )
  ]
