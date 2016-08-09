###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'HauchiwaController', [
    '$rootScope', '$scope', 'Settings', 'ConnectionStatusService', '$http', '$timeout', '$base64', 'TenguGraphModel', 'CurrentUser'
  ($rootScope, $scope, Settings, ConnectionStatusService, $http, $timeout, $base64, TenguGraphModel, CurrentUser) ->

    $scope.hauchiwa = "unknown"
    $scope.status = "init"
    $scope.frame.resetError()
    $scope.autoRefresh = true
    
    $scope.availableModes = ['hauchiwa']
    $scope.tab = $rootScope.stickyTab
    $scope.tab = 'hauchiwa'

    $scope.$watch 'frame.response', (resp) ->
      return unless resp
      console.log(resp)
      if resp.location?
        $scope.hauchiwa = resp.hauchiwa
        $scope.data = resp.data
        $scope.location = resp.location
        if $scope.location == "sojobo"
          console.log("loc=sojobo")
          $scope.sojobo_url = Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/h-" + $scope.hauchiwa
          lookForHauchiwa(resp.data)
        else if $scope.location == "local"
          console.log("loc=local")
          $scope.status = "bundle-check"
          $scope.hauchiwa_url = Settings.endpoint.tengu
          $scope.bundle = resp.data
          refreshLater()
        else if $scope.location.startsWith("http")
          console.log("loc=url")
          if resp.data.charm?
            $scope.sojobo_url = $scope.location
            lookForHauchiwa(resp.data)
          else
            $scope.status = "bundle-check"
            $scope.availableModes.push('graph')
            $scope.availableModes.push('table')
            if resp.data.services?
              $scope.hauchiwa_url = $scope.location
              $scope.hauchiwa = resp.data.environment
              $scope.bundle = resp.data
            else if resp.data.name
              $scope.hauchiwa_models = resp.data.models
              $scope.hauchiwa_url = $scope.location + "/" + $scope.hauchiwa_models[0]
            else
              $scope.status = "error"
              $scope.frame.setError "Could not determine how to reach the Hauchiwa."
              console.log("Could not determine how to reach the Hauchiwa: " + $scope.location + ".")
            refreshLater()
      else
        $scope.status = "error"
        $scope.autoRefresh = no
        $scope.frame.setError resp

    lookForHauchiwa = (data) ->
      if data["service-status"]?
        if data["service-status"].current? and data["service-status"].current == "error"
          $scope.status = "error"
          $scope.frame.setError data["service-status"].message
        else if data["service-status"].current? and data["service-status"].current == "active"
          message = data["service-status"].message
          pfPattern = /^Ready pf:"(?:.*->[0-9]* )*(.*)->5000.*"/
          hauchiwa_ipPort = message.replace(pfPattern, '$1')
          if hauchiwa_ipPort.length != message.length
            $scope.status = "models-check"
            hauchiwa_rooturl = "http://" + hauchiwa_ipPort
            
            sshPattern = /^Ready pf:"(?:.*->[0-9]* )*(.*)->22.*"/
            hauchiwa_sshPort = message.replace(sshPattern, '$1')
            if hauchiwa_sshPort.length != message.length
              $scope.ssh = "ssh://" + hauchiwa_sshPort

            req = {
              "method"  : "GET"
              "url"     : hauchiwa_rooturl
              "headers"  : {"id-token" : CurrentUser.getToken('data_token')}
            }

            $http(req).then(
              (response) ->
                if response.data? and response.data.models?
                  $scope.hauchiwa_models = response.data.models
                  if $scope.hauchiwa_models.length == 1
                    $scope.status = "bundle-check"
                    $scope.availableModes.push('graph')
                    $scope.availableModes.push('table')
                    $scope.model =  $scope.hauchiwa_models[0]  
                    $scope.hauchiwa_url = hauchiwa_rooturl + "/" + $scope.model
                    console.log("Only one model present: " + $scope.hauchiwa_url)
                    refreshLater()
                  else if $scope.hauchiwa_models.length > 1
                    $scope.status = "model-choice"
                    $scope.hauchiwa_url = hauchiwa_rooturl
                    console.log("Multiple models available.")
                else if response.data? and response.data == "Welcome to Hauchiwa API v0.1"
                  $scope.status = "bundle-check"
                  $scope.hauchiwa_url = hauchiwa_rooturl + "/status"
                  console.log("The Hauchiwa still has the old version, using: "+$scope.hauchiwa_url)
                  refreshLater()
                else
                  $scope.status = "error"
                  $scope.frame.setError "Could not retrieve models from the Hauchiwa."
              , (r) ->
                $scope.status = "error"
                $scope.frame.setError "Could not retrieve models from the Hauchiwa."
            )

          else
            console.log("Message '" + message + "' does not contain the correct portforwarding.")
            refreshLater()
        else
          console.log("'service-status' not 'active' yet.")
          refreshLater()
          
    $scope.selectModel = () ->
      $scope.status = "bundle-check"
      $scope.availableModes.push('graph')
      $scope.availableModes.push('table')
      $scope.hauchiwa_url = $scope.hauchiwa_url + "/" + $scope.model
      console.log("User selected model["+$scope.model+"]: " + $scope.hauchiwa_url)
      refreshLater()
      
    $scope.setActive = (tab) ->
      #tab ?= if $scope.tab is 'graph' then 'table' else 'graph'
      $rootScope.stickyTab = $scope.tab = tab

    $scope.isActive = (tab) ->
      tab is $scope.tab

    $scope.isAvailable = (tab) ->
      tab in $scope.availableModes

    refreshHauchiwa = () ->
      if $scope.status != "error" and $scope.status != "bundle-check"
        req = {
          "method"  : "GET"
          "url"     : $scope.sojobo_url
          "headers"  : {"id-token" : CurrentUser.getToken('data_token')}
        }

        $http(req).then(
          (response) ->
            lookForHauchiwa(response.data)
          , (r) ->
            $scope.status = "error"
            console.log("Could not connect to the Sojobo: " + Settings.endpoint.tengu + "/" + $scope.hauchiwa)
            $scope.frame.setError "Could not connect to the Sojobo."
        )
      else
        console.log("'refreshHauchiwa' called again!? [status: "+$scope.status+"]")

    refreshBundle = () ->
      $scope.frame.resetError()
      if $scope.status == "bundle-check"
        req = {
          "method"  : "GET"
          "url"     : $scope.hauchiwa_url
          "headers"  : {"id-token" : CurrentUser.getToken('data_token')}
        }
        $http(req).then(
          (response) ->
            if $scope.hauchiwa == "unknown"
              console.log("Hauchiwa name not yet set")
              $scope.hauchiwa = response.data.environment
              
            $scope.bundle = response.data
            
            if $scope.bundle.services.modelinfo?
              req = {
                "method"  : "GET"
                "url"     : $scope.hauchiwa_url + "/modelinfo/config"
                "headers"  : {"id-token" : CurrentUser.getToken('data_token')}
              }
              $http(req).then(
                (response) ->
                  if response.data.settings?
                    if response.data.settings['modelinfo-version']? and response.data.settings['modelinfo-version'].value == '2.0.0'
                      if response.data.settings['mapping']? and response.data.settings['mapping'].value != ""
                        console.log(response.data.settings['mapping'].value)
                        $scope.bundleGraph = createBundleGraph($scope.bundle.services, response.data.settings['mapping'].value)
                      else
                        console.log("There was no mapping present in the modelinfo (v. 2.0.0)")
                        $scope.bundleGraph = createBundleGraph($scope.bundle.services, null)
                    else 
                      if response.data.settings.type? and response.data.settings.type.value == "web-ui"
                        console.log("This is a model created according to the web-ui's principles, version < 2.0.0.")
                        delete $scope.bundle.services.modelinfo
                        mapping_url = Settings.endpoint.mappings.replace(/{{bundlename}}/g, response.data.settings.tag.value)
                        #mapping_url = Settings.endpoint.bundles + '/' + response.data.settings.tag.value + '.map' 
                        $http.get(mapping_url).
                          success((mapping) ->
                            $scope.bundleGraph = createBundleGraph($scope.bundle.services, mapping)
                          )
                , (r) ->
                  console.log("Could not retrieve the config information of the model. So, only going to show the services.")
                  delete $scope.bundle.services.modelinfo
                  $scope.bundleGraph = createBundleGraph($scope.bundle.services, null)
              )
            else
              console.log("No modelinfo service found. Only show the services.")
              $scope.bundleGraph = createBundleGraph($scope.bundle.services, null)
            
          , (r) ->
            $scope.status = "error"
            $scope.frame.setError "Could not retrieve the status information of the Hauchiwa."
        )
        
    createBundleGraph = (services, mapping) ->
      graph = new neo.models.Graph()
      nodes = []
      relationships = []
      
      if mapping?
        for node in mapping.nodes
          node.id = nodes.length
          node.logical = true
          node.r = 40
          node.cluster_p = []
          nodes.push node
          
          for service in node.services
            relationships.push
              id      : relationships.length
              source  : node.name
              target  : service.name
              logical : true
        
        for relation in mapping.relationships
          relationships.push
            id      : relationships.length
            source  : relation.source
            target  : relation.target
            logical : true
      
      angular.forEach(services, (service, key_s) ->
        node = 
          id        : nodes.length
          name      : key_s
          cluster_p : []
          logical   : false
        
        num_units = 0

        angular.forEach(service.units, (unit, key_u) ->
          switch unit["agent-status"].current
            when "idle" then node.cluster_p.push(1)
            else node.cluster_p.push(0)
          
          num_units++
        )
        node.r = Math.min(5, num_units)*4 + 10
        
        angular.forEach(service.relations, (relation, key_r) ->
          relationships.push
            id      : relationships.length
            source  : key_s
            target  : relation[0]
            label   : key_r
            logical : false
        )

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
      if $scope.status == "bundle-check"
        refreshBundle()
      else
        refreshHauchiwa()

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
