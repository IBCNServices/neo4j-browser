###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'UserInfoCtrl', [
    '$scope'
    'CurrentUser'
    'Frame'
    'Settings'
    '$http'
    '$timeout'
    ($scope, CurrentUser, Frame, Settings, $http, $timeout) ->
      $scope.static_is_authenticated = false
      $scope.static_user = ''
      $scope.models = []

      $scope.$watch 'frame.response', (resp) ->
        return unless resp
        if resp.authenticated?
          $scope.static_is_authenticated = resp.authenticated
          if $scope.static_is_authenticated
            $scope.static_user = CurrentUser.getToken('profile').name

        if resp.userinforeq?
          $http(resp.userinforeq).then(
            (response) ->
              $scope.user_info = response.data
              for ctrl in $scope.user_info.controllers
                console.log ctrl
                if ctrl.models?
                  for model in ctrl.models
                    console.log model
                    $scope.models.push {
                      name       : model.name
                      controller : ctrl.name
                      access     : model.access
                      type       : ctrl.type
                    }
            , (r) ->
              console.log(r)
              $scope.frame.addErrorText "Unknown error: [" + r.status + ", " + r.statusText + "] "
          )

  ]
