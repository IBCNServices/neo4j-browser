###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'BundleGraphCtrl', [
    '$scope'
    '$timeout'
    '$document'
    '$http'
    '$sce'
    '$filter'
    'Settings'
    ($scope, $timeout, $document, $http, $sce, $filter, Settings) ->
      $scope.bundleName = false

      $scope.width = 900;
      $scope.height = 700;

      $scope.nodes = []
      $scope.links = []

      $scope.forceStopped = false

      $scope.clickNode = (node) ->
        if node.href?
          window.open(node.href,'_new')
        true

      $scope.linkStyle = (link) ->
        if link.logical then "marker-end: url('#end-arrow')" else ""

      $scope.linkM = (source, target) ->
        deltaX = target.x - source.x
        deltaY = target.y - source.y
        dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
        normX = deltaX / dist
        normY = deltaY / dist
        sourceX = source.x + ((source.r + 5) * normX)
        sourceY = source.y + ((source.r + 5) * normY)
        targetX = target.x - ((target.r + 5) * normX)
        targetY = target.y - ((target.r + 5) * normY)
        'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY

      $scope.nodeDetails = (node) ->
        if node.logical
          text = '<text x="0" y="4" class="label" text-anchor="middle" font-size="10px" font-weight="bold" stroke="none">'+node.name+'</text>'
          statusM = '<g stroke-width="3" fill="transparent"><path stroke="rgb(0, 140, 193)" d="'+$scope.nodeStatusM(node)+'" /></g>'
          cluster = '<g fill="white" fill-opacity="0.8" stroke="none" transform="translate(0,0)">'
          for c in $scope.nodeCluster(node)
            cluster += '<rect x="'+c.x+'" y="'+c.y+'" width="'+c.size+'" height="'+c.size+'" fill-opacity="'+c.opacity+'"/>'
          cluster += '</g>'
          $sce.trustAsHtml(text+statusM+cluster)
        else
          $sce.trustAsHtml('')

      $scope.nodeStatusM = (node) ->
        if node.cluster_p?
          status = 0
          status += p for p in node.cluster_p
          status = status/node.cluster_p.length
          if status == 1
            'M 0 '+((-1)*node.r)+' A '+node.r+' '+node.r+' 0 1 1 -1 '+((-1)*node.r)+'Z'
          else
            'M 0 '+((-1)*node.r)+' A '+node.r+' '+node.r+' 0 '+(if status<=0.5 then '0' else '1')+' 1 '+(node.r*Math.cos(2.0*status*Math.PI - Math.PI/2.0))+' '+(node.r*Math.sin(2.0*status*Math.PI - Math.PI/2.0))
        else
          'M 0 0'

      $scope.nodeCluster = (node) ->
        size = node.cluster_p.length
        if size == 0
          return []
        else if size == 1
          totalSize = 0.5*node.r
          c =
              x:       totalSize/(-2.0)
              y:       10
              size:    totalSize
              opacity: 0.1 + 0.8*node.cluster_p[x]
          return [c]
        else if size <= 4
          cluster = []
          totalSize = 1.1*node.r
          for x in [0 .. size-1]
            c =
              x:       x*totalSize/size - (totalSize/2.0 - 0.1*totalSize/size)
              y:       10
              size:    0.8*totalSize/size
              opacity: 0.1 + 0.8*node.cluster_p[x]

            cluster.push c
          return cluster

        else
          totalSize = 1.2*node.r
          for diam in [5 .. size]
            cluster = []
            r = parseFloat(diam)/2.0
            maxblocks = Math.ceil(r - .5) * 2 + 1
            actualblocks = 0
            for y in [-maxblocks / 2 + 1 .. maxblocks / 2 - 1]
              if y >= 0
                for x in [-maxblocks / 2 + 1 .. maxblocks / 2 - 1]
                  if Math.sqrt((Math.pow(y, 2)) + Math.pow(x, 2)) <= r
                    c =
                      x:       x-0.5
                      y:       y
                      opacity: 0.1 + 0.8*node.cluster_p[cluster.length]

                    cluster.push(c)
                    if cluster.length >= size
                      if actualblocks == 0
                        actualblocks = cluster.length
                      for c in cluster
                        delta = totalSize/actualblocks
                        c.x = c.x*delta
                        c.y = c.y*delta + Math.min(10,0.7*actualblocks)
                        c.size = 0.8*delta
                      return cluster
                if actualblocks == 0
                  actualblocks = cluster.length
          []


      color = d3.scale.category20()

      $scope.force = d3.layout.force().
                  charge(-2000).
                  linkDistance(80).
                  size([$scope.width, $scope.height])

      tick = (e) ->
        $scope.$apply(() ->
          ##console.log("test:"+e.alpha)
        )

      end = () ->
        console.log("ENDED")
        forceStopped = true
        ##force.stop()

      $scope.drag = (e, node) ->
        $scope.force.start()
        $scope.$apply()

      isLogicalNode = (node) ->
        node.services?

      $scope.$watch '$parent.bundle', (data) ->
        return unless data
        if !$scope.bundleName
          loadBundleMapping(data.services)
        else
          setBundleInfo(data.services)

      loadBundleMapping = (services) ->
        console.log("loadBundleMapping called")
        #Hard-coded ;) Should be more intelligent!
        cityot = 0
        storm = 0
        spark = 0
        angular.forEach(services, (value, key) ->
          if $scope.$parent.location == "local"
            h = key.substring(0, key.indexOf("-"))
            if $scope.$parent.hauchiwa.toLowerCase() != h
              return
            else
              s = key.substring(key.indexOf("-")+1)
          else
            s = key

          switch s
            when "limeds" then cityot++
            when "apache-kafka" then cityot++
            when "nimbus"
              cityot++
              storm++
            when "worker"
              cityot++
              storm++
            when "mongodb" then cityot++
            when "apache-zookeeper"
              cityot++
              storm++
            when "wso2-esb" then cityot++
            when "yarn-master2" then spark++
            when "hdfs-master2" then spark++
            when "spark2" then spark++
            when "plugin2" then spark++
            when "compute-slave2" then spark++
            when "cassandra" then storm++
        )
        if cityot > spark and cityot > storm
          $scope.bundleName = "cityot"
        else if spark > storm
          $scope.bundleName = "spark"
        else
          $scope.bundleName = "storm"

        $http.get(Settings.endpoint.bundles + '/' + $scope.bundleName+'.map').
          success((graph) ->
            for node in graph.nodes
              node.logical = true
              node.r = 40
              node.cluster_p = []
              $scope.nodes.push node
              for service in node.services
                if $scope.$parent.location == "local"
                  ss = services[$scope.$parent.hauchiwa.toLowerCase()+"-"+service.name]
                else
                  ss = services[service.name]

                num_units = 0

                if ss?
                  angular.forEach(ss.units, (unit, key) ->
                    node.cluster_p.push(getClusterP(unit))
                    if node.port? and unit["open-ports"]? and unit["open-ports"].indexOf(node.port+'/tcp') != -1
                      node.href = "http://"+unit["public-address"]+":"+node.port
                      console.log(node.href)
                    num_units++
                  )

                service.logical = false
                service.r = Math.min(5, num_units)*4 + 10
                $scope.nodes.push service

            if graph["shared-services"]?
              for service in graph["shared-services"]
                if $scope.$parent.location == "local"
                  ss = services[$scope.$parent.hauchiwa.toLowerCase()+"-"+service.name]
                else
                  ss = services[service.name]

                num_units = 0

                if ss?
                  angular.forEach(ss.units, (unit, key) ->
                    num_units++
                  )

                service.logical = false
                service.r = Math.min(5, num_units)*4 + 10
                $scope.nodes.push service

            for rel in graph.relationships
              source = $scope.nodes.findIndex((n) -> n.name == rel.source)
              target = $scope.nodes.findIndex((n) -> n.name == rel.target)
              $scope.links.push
                source: source
                target: target
                logical: $scope.nodes[source].logical and $scope.nodes[target].logical

            #$scope.force.drag().on("dragstart", () -> $scope.$apply(()->console.log("dragstart")))

            $scope.force.nodes($scope.nodes).links($scope.links).on("tick", tick).on("end", end).start()

        )

      setBundleInfo = (services) ->
        console.log("setBundleInfo called")
        for node in $scope.nodes
          if node.logical
            node.cluster_p = []
            for s in node.services
              if services[s.name]?
                angular.forEach(services[s.name].units, (unit, key) ->
                  node.cluster_p.push(getClusterP(unit))
                )

      getClusterP = (unit) ->
        switch unit["agent-status"].current
          when "idle" then  1
          else 0

  ]
