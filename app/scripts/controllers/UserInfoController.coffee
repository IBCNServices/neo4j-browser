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
      $scope.controllers = []

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
              if $scope.user_info.access?
                for controller in $scope.user_info.access
                  angular.forEach(controller, (ctrl_data, ctrl_name) ->
                    console.log ctrl_name
                    $scope.controllers.push {
                      name   : ctrl_name
                      access : ctrl_data.access
                      type   : ctrl_data.type
                    }
                    if ctrl_data.models?
                      for model in ctrl_data.models
                        angular.forEach(model, (access, model_name) ->
                          console.log model_name
                          $scope.models.push {
                            name       : model_name
                            controller : ctrl_name
                            access     : access
                            type       : ctrl_data.type
                          }
                        )
                  )
            , (r) ->
              console.log(r)
              $scope.frame.addErrorText "Unknown error: [" + r.status + ", " + r.statusText + "] "
          )

  ]
