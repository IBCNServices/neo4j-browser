###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'ModelMonitoringController', [
    '$rootScope', '$scope', 'Settings', '$http', '$timeout', '$base64', 'TenguGraphModel', 'CurrentUser'
  ($rootScope, $scope, Settings, $http, $timeout, $base64, TenguGraphModel, CurrentUser) ->

    $scope.frame.resetError()
    $scope.model = false
    $scope.controller = false
    $scope.application = false
    $scope.data = null
    $scope.upData = null
    $scope.cpuData = null
    $scope.memData = null
    $scope.fsData = null
    $scope.status = "init"
    $scope.autoRefresh = false
    $scope.busyRefreshing = false

    $scope.availableModes = ['up', 'cpu', 'mem']
    $scope.tab = $rootScope.stickyTab
    $scope.tab = 'up'

    $scope.$watch 'frame.response', (resp) ->
      return unless resp and resp.model
      $scope.model = resp.model
      console.log($scope.model)
      $scope.controller = resp.controller
      if resp.application?
        $scope.application = resp.application
      $scope.req = resp.req

      $scope.data = parseData(resp.data)
      parseUp($scope.data)
      parseCpu($scope.data)
      parseMem($scope.data)
      parseFs($scope.data)

      $scope.status = 'monitoring-checking'
      refreshLater()

    $scope.setActive = (tab) ->
      $rootScope.stickyTab = $scope.tab = tab

    $scope.isActive = (tab) ->
      tab is $scope.tab

    $scope.isAvailable = (tab) ->
      tab in $scope.availableModes

    parseData = (rawData) ->
      metricsList = ["up", "node_memory_MemAvailable", "node_memory_MemFree", "node_memory_MemTotal", "node_cpu", "node_filesystem_avail", "node_filesystem_free", "node_filesystem_size"]
      data = {}
      for m in metricsList
        data[m] = {}
        for d in rawData
          data[m][d.name] = {}
      for d in rawData
        if d.metrics? and d.metrics.data? and d.metrics.data.result? and d.metrics.data.resultType == "vector"
          for m in d.metrics.data.result
            if m.metric.__name__ in metricsList
              data[m.metric.__name__][d.name][m.value[0]] = m.value[1]
      data

    parseUp = (data) ->
      $scope.upData = {}
      angular.forEach(data.up, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.upData[unit] = value
        )
      )

    parseCpu = (data) ->
      $scope.cpuData = {}
      angular.forEach(data.node_cpu, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.cpuData[unit] = value
        )
      )

    parseMem = (data) ->
      $scope.memData = {}
      angular.forEach(data.node_memory_MemAvailable, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.memData[unit] = {"available":Math.ceil(value/1024.0/1024.0)}
        )
      )
      angular.forEach(data.node_memory_MemTotal, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.memData[unit].total = Math.ceil(value/1024.0/1024.0)
        )
      )
      angular.forEach(data.node_memory_MemFree, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.memData[unit].free = Math.ceil(value/1024.0/1024.0)
        )
      )

    $scope.memState = (value) ->
      percentage = value.available/value.total
      if (percentage < 0.2)
        return "panel-danger"
      else if (percentage < 0.4)
        return "panel-warning"
      else
        return "panel-success"

    parseFs = (data) ->
      $scope.fsData = {}
      angular.forEach(data.node_filesystem_avail, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.fsData[unit] = {"available": parseFloat(value)}
        )
      )
      angular.forEach(data.node_filesystem_size, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.fsData[unit].total = parseFloat(value)
        )
      )
      angular.forEach(data.node_filesystem_free, (metrics, unit) ->
        angular.forEach(metrics, (value, ts) ->
          $scope.fsData[unit].free = parseFloat(value)
        )
      )
      angular.forEach($scope.fsData, (metrics, unit) ->
        $scope.fsData[unit].used = metrics.total - metrics.available
      )
      console.log($scope.fsData)

    refreshModel = () ->
      $scope.busyRefreshing = true
      $scope.frame.resetError()
      if $scope.status == "monitoring-checking"
        $http($scope.req).then(
          (response) ->
            $scope.data = parseData(response.data)
            parseUp($scope.data)
            parseCpu($scope.data)
            parseMem($scope.data)
            parseFs($scope.data)
            $scope.busyRefreshing = false
          , (r) ->
            $scope.status = "error"
            $scope.frame.setError "Could not retrieve Model [" + $scope.modelName + "] information."
            $scope.busyRefreshing = false
        )


    $scope.refresh = () ->
      if $scope.status == "monitoring-checking" and !$scope.busyRefreshing
        console.log "Refreshing the monitoring info"
        refreshModel()
      else
        console.log "Not refreshing the monitoring info, still busy."

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
