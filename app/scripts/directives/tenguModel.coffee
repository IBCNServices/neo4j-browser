###!

###

'use strict';

# Requires jQuery
angular.module('neo4jApp.directives')
  .directive('tenguModel', ['$rootScope', 'Frame','Settings', ($rootScope, Frame, Settings) ->
    restrict: 'A'
    link: (scope, element, attrs) ->

      model = attrs.tenguModel
      command = "tengu model create"

      if model
        element.on 'click', (e) ->
          e.preventDefault()

          model = model.toLowerCase().trim()
          Frame.create(input: "#{Settings.cmdchar}#{command} #{model}")

          $rootScope.$apply() unless $rootScope.$$phase

  ])
