###!

###

'use strict';

# Requires jQuery
angular.module('neo4jApp.directives')
  .directive('viewModel', ['$rootScope', 'Frame','Settings', ($rootScope, Frame, Settings) ->
    restrict: 'A'
    link: (scope, element, attrs) ->

      model = attrs.viewModel
      command = "tengu model status"

      if model
        element.on 'click', (e) ->
          e.preventDefault()

          model = model.toLowerCase().trim()
          Frame.create(input: "#{Settings.cmdchar}#{command} #{model}")

          $rootScope.$apply() unless $rootScope.$$phase

  ])
