###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'UserDeleteController', [
    '$scope', 'Settings', '$http', '$timeout', '$base64', 'Frame', 'CurrentUser'
  ($scope, Settings, $http, $timeout, $base64, Frame, CurrentUser) ->
    $scope.frame.resetError()
    $scope.user = ''

    $scope.status = "init"

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.user = resp.user
      $scope.status = "confirm"

    $scope.removeUser = ->
      if not $scope.user? || not $scope.user.length
        $scope.frame.addErrorText 'You have to tell us which user you want to remove. '
      if $scope.frame.getDetailedErrorText().length
        $scope.errorMessage = $scope.frame.getDetailedErrorText()
        $scope.status = "error"
        return

      $scope.status = "deleting"
      $scope.frame.resetError()
      basicAuth = CurrentUser.getToken('token')

      req = {
        "method"  : "DELETE"
        "url"     : Settings.endpoint.tengu + "/users/" + $scope.user
        "headers" : {
          "Content-Type"  : "application/json"
          "api-key"       : Settings.apiKey
          "Authorization" : "Basic " + basicAuth
        }
      }

      $http(req).then(
        (response) ->
          $scope.status = "deleted"
          $scope.frame.resetError()
          $scope.focusEditor()
        , (r) ->
          console.log(r)
          $scope.status = "error"
          $scope.errorMessage = r.data.message
          $scope.frame.setError "There was an error in deleting the Model"
      )

]
