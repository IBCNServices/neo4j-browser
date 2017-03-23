###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'TenguCtrl', [
    '$scope'
    'CurrentUser'
    'Frame'
    'Settings'
    ($scope, CurrentUser, Frame, Settings) ->
      $scope.static_is_authenticated = CurrentUser.isAuthenticated()

      if (!$scope.static_is_authenticated)
        Frame.createOne({input:"#{Settings.cmdchar}signin"})

      $scope.bundle = (bundle) ->
        $scope.frame.resetError()
        Frame.create {input: "#{Settings.cmdchar}tengu bundle #{bundle}"}

  ]
