###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ModelDeleteController', [
    '$scope', 'Settings', '$http', '$timeout', '$base64', 'Frame', 'CurrentUser'
  ($scope, Settings, $http, $timeout, $base64, Frame, CurrentUser) ->
    $scope.frame.resetError()
    $scope.model = ''
    $scope.controller = null

    $scope.status = "init"
    $scope.is_authenticated = CurrentUser.isAuthenticated()

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.model = resp.modelName
      $scope.controller = resp.controller
      $scope.status = "confirm"

    $scope.deleteModel = ->
      if not $scope.model? || not $scope.model.length
        $scope.frame.addErrorText 'You have to enter a name for the Model. '
      if $scope.frame.getDetailedErrorText().length
        $scope.status = "start"
        return

      $scope.status = "deleting"
      $scope.frame.resetError()
      static_user = CurrentUser.getToken('profile').name
      basicAuth = CurrentUser.getToken('token')

      req = {
        "method"  : "DELETE"
        "url"     : Settings.endpoint.tengu + "/tengu/controllers/" + $scope.controller + "/models/" + $scope.model
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
