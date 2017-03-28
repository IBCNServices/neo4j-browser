###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ModelController', [
    '$rootScope', '$scope', 'Settings', '$http', '$timeout', '$base64', 'TenguGraphModel', 'CurrentUser'
  ($rootScope, $scope, Settings, $http, $timeout, $base64, TenguGraphModel, CurrentUser) ->

    $scope.frame.resetError()
    $scope.modelName = false
    $scope.controller = false
    $scope.model = false
    $scope.modelUI = false
    $scope.status = "init"
    $scope.autoRefresh = true
    $scope.busyRefreshing = false

    $scope.availableModes = ['model']
    $scope.tab = $rootScope.stickyTab
    $scope.tab = 'model'

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      console.log(resp)
      $scope.modelName = resp.modelName
      if resp.controller?
        $scope.controller = resp.controller
      $scope.model = resp.data
      $scope.req = resp.req
      $scope.modelUI = $scope.model["juju-gui-url"]

      $scope.status = "model-check"
      if $scope.model.applications? and $scope.model.applications.length > 0
        $scope.modelGraph = createModelGraph($scope.model.applications, null)
        $scope.availableModes.push('graph')
        $scope.availableModes.push('table')
      refreshLater()

    $scope.setActive = (tab) ->
      #tab ?= if $scope.tab is 'graph' then 'table' else 'graph'
      $rootScope.stickyTab = $scope.tab = tab

    $scope.isActive = (tab) ->
      tab is $scope.tab

    $scope.isAvailable = (tab) ->
      tab in $scope.availableModes

    refreshModel = () ->
      $scope.busyRefreshing = true
      $scope.frame.resetError()
      if $scope.status == "model-check"
        $http($scope.req).then(
          (response) ->
            $scope.model = response.data
            $scope.modelGraph = createModelGraph($scope.model.applications, null)
            $scope.busyRefreshing = false
          , (r) ->
            $scope.status = "error"
            $scope.frame.setError "Could not retrieve Model [" + $scope.modelName + "] information."
            $scope.busyRefreshing = false
        )

    createModelGraph = (applications, mapping) ->
      console.log "mapping: " + mapping
      $scope.$emit('reset.frame.views')

      graph = new neo.models.Graph()
      nodes = []
      relationships = []

      if mapping? and mapping.nodes?
        for node in mapping.nodes
          node.id = nodes.length
          node.logical = true
          node.r = 40
          node.cluster_p = []
          node.controller = $scope.controller
          node.model = $scope.modelName
          nodes.push node

          if node.services?
            for service in node.services
              relationships.push
                id      : relationships.length
                source  : node.name
                target  : service.name
                logical : true

        if mapping.relationships?
          for relation in mapping.relationships
            relationships.push
              id      : relationships.length
              source  : relation.source
              target  : relation.target
              logical : true

      angular.forEach(applications, (app) ->
        node =
          id        : nodes.length
          name      : app.name
          cluster_p : []
          logical   : false
          controller: $scope.controller
          model     : $scope.modelName

        num_units = 0

        if app.units?
          for unit in app.units
            ###
            switch unit["agent-status"].current
              when "idle" then node.cluster_p.push(1)
              else node.cluster_p.push(0)
            ###
            node.cluster_p.push(1)
            num_units++
        else
          console.log "[" + app.name + "] has no units, subordinate?"

        node.r = Math.min(5, num_units)*4 + 10

        if app.relations?
          for relation in app.relations
            relationships.push
              id      : relationships.length
              source  : app.name
              target  : relation.with
              label   : relation.interface
              logical : false

        nodes.push node
      )



      nodes = nodes
        .map(TenguGraphModel.convertNode())
        .filter((node)-> return node)
      graph.addNodes(nodes)

      for relation in relationships
        if !graph.findNode(relation.source)?
          graph.addNodes([new neo.models.Node(relation.source, ['Missing'], {0: relation.source})])
        if !graph.findNode(relation.target)?
          graph.addNodes([new neo.models.Node(relation.target, ['Missing'], {0: relation.target})])


      relationships = relationships
        .map(TenguGraphModel.convertRelationship(graph))
        .filter((rel)-> return rel)
      graph.addRelationships(relationships)

      graph

    $scope.refresh = () ->
      if $scope.status == "model-check" and !$scope.busyRefreshing
        console.log "Refreshing the model"
        refreshModel()
      else
        console.log "Not refreshing the model, still busy."

    # FIX: timer should take the current request into account
    timer = null
    refreshLater = () =>
      $timeout.cancel(timer)
      if $scope.status == "error"
        $scope.autoRefresh = no
      else if $scope.autoRefresh and !$scope.frame.isTerminating
        $scope.refresh()
        timer = $timeout(
          refreshLater
          ,
          (Settings.refreshInterval * 1000)
        )

    $scope.toggleAutoRefresh = () ->
      $scope.autoRefresh = !$scope.autoRefresh
      refreshLater()

]
