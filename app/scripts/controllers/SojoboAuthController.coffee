###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'SojoboAuthCtrl', [
    '$scope'
    'CurrentUser'
    'Frame'
    'Settings'
    '$http'
    '$timeout'
    ($scope, CurrentUser, Frame, Settings, $http, $timeout) ->
      $scope.username = ''
      $scope.password = ''
      $scope.sshKey = ''
      $scope.credential = ''
      $scope.name = ''
      $scope.type = ''
      $scope.static_user = ''

      $scope.$watch 'frame.response', (resp) ->
        return unless resp
        if resp.authenticated?
          $scope.static_is_authenticated = resp.authenticated
          if $scope.static_is_authenticated
            $scope.static_user = CurrentUser.getToken('profile').name

      $scope.signin = () ->
        $scope.frame.resetError()

        if not $scope.username? || not $scope.username.length
          $scope.frame.addErrorText 'You have to enter a username to sign in. '
        if not $scope.password? || not $scope.password.length
          $scope.frame.addErrorText 'You have to enter a password. We do not check the password strength.'
        return if $scope.frame.getDetailedErrorText().length

        CurrentUser.login($scope.username, $scope.password)
        .then( () ->
          $scope.static_user = $scope.username
          Frame.createOne({input:"#{Settings.initCmd}"})
          $scope.focusEditor()
        , (r) ->
          CurrentUser.logout()
          $scope.static_user = ''
          $scope.frame.addErrorText "Something went wrong while login in to the Sojobo: " + r.data
        ).then ( () ->
          $scope.static_is_authenticated = CurrentUser.isAuthenticated()
        )

      $scope.changePassword = () ->
        if not $scope.password? || not $scope.password.length
          $scope.frame.addErrorText 'You have to enter a password. We do not check the password strength.'
        return if $scope.frame.getDetailedErrorText().length

        url = Settings.endpoint.tengu + "/users/" + $scope.static_user
        basicAuth = CurrentUser.getToken('token')

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
            CurrentUser.login($scope.static_user, $scope.password)
            .then( ->
              $scope.static_is_authenticated = CurrentUser.isAuthenticated()
              $scope.frame.resetError()
            , (r)->
              $scope.frame.addErrorText "Something went wrong while login in to the Sojobo: " + r
            )
          , (r) ->
            console.log(r)
            $scope.frame.setError "There was an error in changing the Password: " + r.data
        )

      $scope.addSshKey = () ->
        if not $scope.sshKey? || not $scope.sshKey.length
          $scope.frame.addErrorText 'You have to provide a valid SSH-key.'
        return if $scope.frame.getDetailedErrorText().length

        url = Settings.endpoint.tengu + "/users/" + $scope.static_user + "/ssh"
        basicAuth = CurrentUser.getToken('token')

        req = {
          "method"  : "POST"
          "url"     : url
          "headers"  : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          }
          "data"    : {
            "ssh-key"    : $scope.sshKey
          }
        }

        $http(req).then(
          (response) ->
            Frame.createOne({input:"#{Settings.cmdchar}tengu user info"})
          , (r) ->
            console.log(r)
            $scope.frame.setError "There was an error in adding the SSH-key: " + r.data
        )

      $scope.addCredential = () ->
        if not $scope.name? || not $scope.name.length
          $scope.frame.addErrorText 'You have to provide a unique name.'
        if not $scope.type? || not $scope.type.length
          $scope.frame.addErrorText 'You have to set the cloud type.'
        if not $scope.credential? || not $scope.credential.length
          $scope.frame.addErrorText 'You have to provide a correct Credential.'
        return if $scope.frame.getDetailedErrorText().length

        try
          credential_json = JSON.parse($scope.credential)

        catch error
          $scope.frame.addErrorText 'There was a syntax error in the credential you provided: ' + error + '. '
          return

        url = Settings.endpoint.tengu + "/users/" + $scope.static_user + "/credentials"
        basicAuth = CurrentUser.getToken('token')

        req = {
          "method"  : "POST"
          "url"     : url
          "headers"  : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          }
          "data"    : {
            "name"        : $scope.name
            "c_type"      : $scope.type
            "credentials" : credential_json
          }
        }

        $http(req).then(
          (response) ->
            Frame.createOne({input:"#{Settings.cmdchar}tengu user info"})
          , (r) ->
            console.log(r)
            $scope.frame.setError "There was an error in adding the credential: " + r.data
        )

  ]
