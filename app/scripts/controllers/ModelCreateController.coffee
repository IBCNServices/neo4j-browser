###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ModelCreateController', [
    '$scope', 'Settings', '$http', '$timeout', '$base64', 'Frame', 'CurrentUser'
  ($scope, Settings, $http, $timeout, $base64, Frame, CurrentUser) ->
    $scope.frame.resetError()
    $scope.newModel = null
    $scope.controller = false
    $scope.controllers = []
    $scope.bundle = null
    $scope.ssh_key = null

    $scope.status = "start"
    ssh_key_pattern = /^ssh-rsa [A-Za-z0-9+]+ \w+@\w+/
    $scope.is_authenticated = CurrentUser.isAuthenticated()

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      if $scope.frame.hasErrors
        $scope.status = "start"
      else
        $scope.newModel = resp.modelName
        if resp.controller?
          $scope.controller = resp.controller
        else
          req = {
            "method"  : "GET"
            "url"     : Settings.endpoint.tengu + "/users/" + CurrentUser.getToken('profile').name
            "headers"  : {
              "Content-Type"  : "application/json"
              "api-key"       : Settings.apiKey
              "Authorization" : "Basic " + CurrentUser.getToken('token')
            }
          }
          $http(req).then(
            (response) ->
              if response.data.access?
                for controller in response.data.access
                  angular.forEach(controller, (ctrl_data, ctrl_name) ->
                    console.log ctrl_name
                    $scope.controllers.push {
                      name   : ctrl_name
                      access : ctrl_data.access
                      type   : ctrl_data.type
                    }
                  )
            , (r) ->
              console.log(r)
              $scope.frame.setError "There was an error in getting the Environments for this user: " + r.data
          )
        if resp.bundle?
          $scope.bundle = resp.bundle
        $scope.createModel()

    $scope.checkStatus = () ->
      Frame.create {input: "#{Settings.cmdchar}tengu model status #{$scope.newModel}@#{$scope.controller}"}

    $scope.createModel = ->
      $scope.status = "creating.model"
      $scope.frame.resetError()

      if not $scope.newModel? || not $scope.newModel.length
        $scope.frame.addErrorText 'You have to enter a name for the Model. '
      if not $scope.controller || not $scope.controller.length
        $scope.frame.addErrorText 'You have to provide the environment to deploy this Model to. '
      #if $scope.ssh_key? && not ssh_key_pattern.test($scope.ssh_key)
      #  $scope.frame.addErrorText 'The SSH key field does not have the correct format. '

      if $scope.frame.getDetailedErrorText().length
        $scope.status = "start"
        return
      else
        deployModel()

    deployModel = ->
      static_user = CurrentUser.getToken('profile').name
      basicAuth = CurrentUser.getToken('token')

      req = {
        "method"  : "POST"
        "url"     : Settings.endpoint.tengu + "/tengu/controllers/" + $scope.controller + "/models"
        "headers" : {
          "Content-Type"  : "application/json"
          "api-key"       : Settings.apiKey
          "Authorization" : "Basic " + basicAuth
        }
        "data"    : {
          "model"    : $scope.newModel
        }
      }

      $http(req).then(
        (response) ->
          #Add ssh_key
          $scope.status = "created.model"

          if $scope.bundle?
            $scope.status = "creating.bundle"
            req = {
              "method"  : "POST"
              "url"     : Settings.endpoint.tengu + "/tengu/controllers/" + $scope.controller + "/models/" + $scope.newModel
              "headers" : {
                "Content-Type"  : "application/json"
                "api-key"       : Settings.apiKey
                "Authorization" : "Basic " + basicAuth
              }
              "data"    : {
                "bundle" : $scope.bundle
              }
            }

            $http(req).then(
              (response) ->
                $scope.status = "finished"
                $scope.frame.resetError()
                $scope.focusEditor()
              , (r) ->
                console.log(r)
                $scope.status = "start"
                $scope.frame.setError "There was an error in deploying the bundle: " + r.data
            )
          else
            $scope.status = "finished"
            $scope.focusEditor()
            $scope.frame.resetError()
        , (r) ->
          console.log(r)
          $scope.status = "start"
          $scope.frame.setError "There was an error in creating the Model: " + r.data
      )

]
