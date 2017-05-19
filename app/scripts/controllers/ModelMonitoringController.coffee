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

    $scope.availableModes = ['waiting']
    $scope.tab = 'waiting'
    $scope.tab = $rootScope.stickyTab

    $scope.$watch 'frame.response', (resp) ->
      return unless resp and resp.model
      $scope.model = resp.model
      console.log($scope.model)
      $scope.controller = resp.controller
      if resp.application?
        $scope.application = resp.application
      $scope.req = resp.req

      $http($scope.req).then(
        (response) ->
          hasData = parseData(response.data)
          console.log($scope.data)
          if hasData
            $scope.availableModes = ['up', 'cpu', 'mem', 'fs']
            $scope.tab = 'up'

            $scope.upData = parseUp($scope.data)
            $scope.cpuData = parseCpu($scope.data)
            $scope.memData = parseMem($scope.data)
            $scope.fsData = parseFs($scope.data)

            $scope.status = 'monitoring-checking'
            refreshLater()
          else
            $scope.availableModes = ['install']
            $scope.tab = 'install'
        , (r) ->
          if r.status == 404
            console.log(r.data.msg)
            $scope.frame.addErrorText "Could not find the Model or Application '" + modAndApp + "'"
          else
            console.log(r)
            $scope.frame.addErrorText "Unknown error: [" + r.status + ", " + r.data + "] "
      )

    $scope.setActive = (tab) ->
      $rootScope.stickyTab = $scope.tab = tab

    $scope.isActive = (tab) ->
      tab is $scope.tab

    $scope.isAvailable = (tab) ->
      tab in $scope.availableModes

    $scope.addMonitoring = ->
      $scope.status = 'monitoring-add'
      req = {
        "method"  : "PUT"
        "url"     : $scope.req.url
        "headers"  : $scope.req.headers
      }

      $http(req).then(
        (response) ->
          $scope.availableModes = ['up', 'cpu', 'mem', 'fs']
          $scope.tab = 'up'

          parseData(resp.data)
          parseUp($scope.data)
          parseCpu($scope.data)
          parseMem($scope.data)
          parseFs($scope.data)

          $scope.status = 'monitoring-checking'
          refreshLater()
        , (r) ->
          console.log(r)
          $scope.frame.addErrorText "Error: [" + r.status + ", " + r.statusText + "] "
      )

    parseData = (rawData) ->
      console.log rawData
      metricsList = ["disk", "cpu_load", "memory", "keepalive"]
      data = {}
      hasData = false
      for m in metricsList
        data[m] = {}
      angular.forEach(rawData, (raw_i, unit) ->
        for d in raw_i
          if d.type? and d.type in metricsList
            hasData = true
            if $scope.application?
              data[d.type][$scope.application+"/"+unit] = d.result
            else
              data[d.type][$scope.model+"/"+unit] = d.result
      )
      $scope.data = data
      hasData


    parseUp = (data) ->
      #e.g. Keepalive sent from client 4 seconds ago
      upData = {}
      angular.forEach(data.keepalive, (metric, unit) ->
        upData[unit] = metric.startsWith('Keepalive sent from client')
      )
      upData

    parseCpu = (data) ->
      #e.g. CheckLoad OK: Total load average (1 CPU): 0.09, 1.42, 1.49\n
      cpuData = {}
      angular.forEach(data.cpu_load, (metric, unit) ->
        numberOfCPU = metric.substring(metric.indexOf('(')+1, metric.indexOf(' CPU'))
        percentages = metric.substring(metric.lastIndexOf(':')+2).split(',')
        cpuData[unit] =
          cpu : percentages
          nr  : numberOfCPU
      )
      console.log(cpuData)
      cpuData

    parseMem = (data) ->
      #e.g. juju-297e3c-6.memory.total 1778352128 1494790616\njuju-297e3c-6.memory.free 579596288 1494790616\njuju-297e3c-6.memory.buffers 135917568 1494790616\njuju-297e3c-6.memory.cached 758579200 1494790616\njuju-297e3c-6.memory.swapTotal 0 1494790616\njuju-297e3c-6.memory.swapFree 0 1494790616\njuju-297e3c-6.memory.dirty 49152 1494790616\njuju-297e3c-6.memory.swapUsed 0 1494790616\njuju-297e3c-6.memory.used 1198755840 1494790616\njuju-297e3c-6.memory.usedWOBuffersCaches 304259072 1494790616\njuju-297e3c-6.memory.freeWOBuffersCaches 1474093056 1494790616\n
      memData = {}
      angular.forEach(data.memory, (metric, unit) ->
        memData[unit] = {}
        for line in metric.split('\n')
          if line.indexOf("total") != -1
            tokens = line.split(' ')
            memData[unit].total = Math.ceil(tokens[1]/1024.0/1024.0)
          if line.indexOf("free") != -1
            tokens = line.split(' ')
            memData[unit].free = Math.ceil(tokens[1]/1024.0/1024.0)
          if line.indexOf("used") != -1
            tokens = line.split(' ')
            memData[unit].used = Math.ceil(tokens[1]/1024.0/1024.0)
      )
      console.log(memData)
      memData

    $scope.memState = (value) ->
      percentage = value.free/value.total
      if (percentage < 0.2)
        return "panel-danger"
      else if (percentage < 0.4)
        return "panel-warning"
      else
        return "panel-success"

    parseFs = (data) ->
      #e.g. CheckDisk OK: All disk usage under 85% and inode usage under 85%\n
      fsData = {}
      angular.forEach(data.disk, (metric, unit) ->
        state = metric.substring('CheckDisk '.length, metric.indexOf(':')).toLowerCase()
        if state == "ok"
          usaged = metric.substring(metric.indexOf('under ')+'under '.length, metric.indexOf('%'))
          usagei = metric.substring(metric.lastIndexOf('under ')+'under '.length, metric.lastIndexOf('%'))
          usage  = [usaged, usagei]
        else
          usage = null
        fsData[unit] =
          state  : state
          usage  : usage
          report : metric
      )
      console.log fsData
      fsData

    $scope.fsState = (value) ->
      if value.state == "critical"
        return "panel-danger"
      else if value.state == "waring"
        return "panel-warning"
      else
        return "panel-success"

    refreshModel = () ->
      $scope.busyRefreshing = true
      $scope.frame.resetError()
      if $scope.status == "monitoring-checking"
        $http($scope.req).then(
          (response) ->
            parseData(response.data)
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
