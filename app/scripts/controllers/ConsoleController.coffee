###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ConsoleController', [
    '$scope',
  ($scope) ->

    $scope.hauchiwa = ''
    $scope.console_url = ''
    $scope.show_console = false
    $scope.frame.resetError()

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      $scope.hauchiwa = resp.hauchiwa
      $scope.console_url = resp.console_url
      $scope.show_console = true
      console.log "in watch: "+resp.console_url

]
