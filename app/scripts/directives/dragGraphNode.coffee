###!

###

'use strict';

angular.module('neo4jApp.directives')
  .directive 'dragGraphNode', ['$document', ($document) ->
    link: (scope, element, attrs) ->
      node = scope.nodes[attrs.dragGraphNode]
      op = 1

      element.on('mousedown', (event) ->
      	if !scope.forceStopped
          node.fixed = false
          event.preventDefault()
          op = element.css ("opacity")
          element.css( 
            opacity: 0.5
          )
          $document.on('mousemove', mousemove)
          $document.on('mouseup', mouseup)
      )

      mousemove = (event) ->
        node.fixed = true
        node.x = event.offsetX
        node.y = event.offsetY
        scope.$apply()

      mouseup = () ->
        element.css( 
          opacity: op 
        )
        $document.off('mousemove', mousemove)
        $document.off('mouseup', mouseup)
  ]