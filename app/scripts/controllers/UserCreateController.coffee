###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'UserCreateController', [
    '$scope', 'Settings', '$http', 'Frame', 'CurrentUser'
  ($scope, Settings, $http, Frame, CurrentUser) ->
    $scope.frame.resetError()
    $scope.newUser = null
    $scope.newPassword = null
    $scope.status = "start"
    $scope.is_authenticated = CurrentUser.isAuthenticated()

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      if $scope.frame.hasErrors
        $scope.status = "start"
      else
        $scope.createUser()

    $scope.checkStatus = () ->
      Frame.create {input: "#{Settings.cmdchar}tengu user grant "+$scope.newUser}

    $scope.createUser = ->
      $scope.status = "creating.user"
      $scope.frame.resetError()

      if not $scope.newUser? || not $scope.newUser.length
        $scope.frame.addErrorText 'You have to provide a user name. '
      if not $scope.newPassword? || not $scope.newPassword.length
        $scope.frame.addErrorText 'You have to provide a password. '

      if $scope.frame.getDetailedErrorText().length
        $scope.status = "start"
        return
      else
        static_user = CurrentUser.getToken('profile').name
        basicAuth = CurrentUser.getToken('token')

        req = {
          "method"  : "POST"
          "url"     : Settings.endpoint.tengu + "/users"
          "headers" : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          }
          "data"    : {
            "username" : $scope.newUser
            "password" : $scope.newPassword
          }
        }

        $http(req).then(
          (response) ->
            $scope.status = "finished"
            $scope.focusEditor()
            $scope.frame.resetError()
          , (r) ->
            console.log(r)
            $scope.status = "start"
            $scope.frame.setError "There was an error in creating the User: " + r.data
        )

]
