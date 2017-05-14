###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'UserGrantController', [
    '$scope'
    'CurrentUser'
    'Frame'
    'Editor'
    'Settings'
    '$http'
    '$timeout'
    '$rootScope'
    ($scope, CurrentUser, Frame, Editor, Settings, $http, $timeout, $rootScope) ->
      $scope.static_is_authenticated = false
      $scope.static_user = ''
      $scope.success = []
      $scope.error = []
      $scope.access = {}
      $scope.otherUsers = []
      $scope.static_user_access = null
      $scope.controller_acl_options = ['login', 'add-model', 'superuser']
      $scope.model_acl_options = ['read', 'write', 'admin']

      $scope.selectedUser = null
      $scope.selectedUserModelACL = {}

      $scope.availableModes = ['controllers', 'models', 'user']
      $scope.tab = $rootScope.stickyTab
      $scope.tab = 'controllers'

      $scope.setActive = (tab) ->
        $rootScope.stickyTab = $scope.tab = tab

      $scope.isActive = (tab) ->
        tab is $scope.tab

      $scope.isAvailable = (tab) ->
        tab in $scope.availableModes


      $scope.$watch 'frame.response', (resp) ->
        return unless resp
        if resp.authenticated?
          $scope.static_is_authenticated = resp.authenticated
          if $scope.static_is_authenticated
            $scope.static_user = CurrentUser.getToken('profile').name

        if resp.userlistreq?
          $http(resp.userlistreq).then(
            (response) ->
              response.data
              if response.data.length > 0
                for user in response.data
                  if user.active
                    if user.name != $scope.static_user
                      $scope.otherUsers.push(user.name)

                    u = {
                      controllers : {}
                      models     : {}
                    }
                    if user.access?
                      for ctrl in user.access
                        angular.forEach(ctrl, (ctrl_data, ctrl_name) ->
                          u.controllers[ctrl_name] =
                            access : ctrl_data.access
                            type   : ctrl_data.type
                          if ctrl_data.models?
                            for model in ctrl_data.models
                              angular.forEach(model, (access, model_name) ->
                                u.models[model_name] =
                                  controller : ctrl_name
                                  access     : access
                                  type       : ctrl_data.type
                              )
                        )
                    $scope.access[user.name] = u
              console.log $scope.access
            , (r) ->
              console.log(r)
              $scope.frame.addErrorText "Unknown error: [" + r.status + ", " + r.statusText + "] "
          )

      $scope.userSelected = (user) ->
        if $scope.access[user]?
          angular.forEach($scope.access[user].models, (model, model_name) ->
            $scope.selectedUserModelACL[model_name] = model.access
          )

      recurrentLookup = (req, controllerOrModel, newAccess, msg) ->
        console.log("start recurring for "+controllerOrModel)
        $http(req).then(
          (response) ->
            if response.data[controllerOrModel].access == newAccess
              $scope.success.push(msg)
              $scope.editor.setMessage(msg)
            else
              $timeout(() ->
                recurrentLookup(req, controllerOrModel, newAccess, msg)
              , 2000)
          , (r) ->
            console.log(r)
            $scope.error.push(msgError)
            $scope.frame.setError "There was an error in checking the ACL: " + r.data
        )

      $scope.changeControllerACL = (user, controller, access) ->
        req = {
          "method"  : "PUT"
          "url"     : Settings.endpoint.tengu + "/users/" + user + "/controllers/" + controller
          "headers" : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + CurrentUser.getToken('token')
          }
          "data"    : {
            "access" : access
          }
        }

        $http(req).then(
          (response) ->
            req.method = "GET"
            req.data = null
            recurrentLookup(req, controller, access, "Changing ACL for user " + user + " on environment " + controller + " is finished. Current ACL is " + access)
          , (r) ->
            console.log(r)
            $scope.error.push("Changing ACL for user " + user + " on environment " + controller + " failed.")
            $scope.frame.setError "There was an error in changing the ACL: " + r.data
        )

      $scope.changeModelACL = (user, model, controller, access) ->
        req = {
          "method"  : "PUT"
          "url"     : Settings.endpoint.tengu + "/users/" + user + "/controllers/" + controller + "/models/" + model
          "headers" : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + CurrentUser.getToken('token')
          }
          "data"    : {
            "access" : access
          }
        }

        $http(req).then(
          (response) ->
            req.method = "GET"
            req.data = null
            recurrentLookup(req, model, access, "Changing ACL for user " + user + " on model " + model + "@" + controller + " is finished. Current ACL is " + access)
          , (r) ->
            console.log(r)
            $scope.error.push("Changing ACL for user " + user + " on model " + model + "@" + controller + " failed.")
            $scope.frame.setError "There was an error in changing the ACL: " + r.data
        )

  ]
