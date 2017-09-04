###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'UserInfoCtrl', [
    '$rootScope'
    '$scope'
    'CurrentUser'
    'Frame'
    'Settings'
    '$http'
    '$timeout'
    ($rootScope, $scope, CurrentUser, Frame, Settings, $http, $timeout) ->
      $scope.static_is_authenticated = false
      $scope.static_user = ''
      $scope.models = []
      $scope.controllers = []
      $scope.credentials = []
      $scope.sshKeys = []

      $scope.availableModes = ['info', 'keys', 'creds']
      $scope.tab = $rootScope.stickyTab
      $scope.tab = 'info'

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

        if resp.userinforeq?
          $http(resp.userinforeq).then(
            (response) ->
              $scope.user_info = response.data
              if $scope.user_info.controllers?
                for controller in $scope.user_info.controllers
                  console.log controller.name
                  $scope.controllers.push {
                    name   : controller.name
                    access : controller.access
                    type   : controller.type
                  }
                  if controller.models?
                    for model in controller.models
                      console.log model.name
                      $scope.models.push {
                        name       : model.name
                        controller : controller.name
                        access     : model.access
                        type       : controller.type
                      }
              if $scope.user_info["ssh-keys"]?
                $scope.sshKeys = $scope.user_info["ssh-keys"]
              if $scope.user_info.credentials?
                for cred in $scope.user_info.credentials
                  $scope.credentials.push {
                    name   : cred.name
                    type   : cred.type
                    cloud  : cred.cloud
                  }
            , (r) ->
              console.log(r)
              $scope.frame.addErrorText "Unknown error: [" + r.status + ", " + r.statusText + "] "
          )

  ]
