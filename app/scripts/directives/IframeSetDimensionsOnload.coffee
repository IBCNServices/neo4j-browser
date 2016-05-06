###!

###

'use strict';

angular.module('neo4jApp.directives')
  .directive('iframeSetDimensionsOnload', ['$rootScope', 'Settings', ($rootScope, Settings) ->
    restrict: 'A'
    link: (scope, element, attrs) ->

      element.on('load', () ->
        iFrameHeight = element[0].contentWindow.document.body.scrollHeight + 'px'
        iFrameWidth = '100%'
        element.css('width', iFrameWidth)
        element.css('height', iFrameHeight)
      )

  ])
