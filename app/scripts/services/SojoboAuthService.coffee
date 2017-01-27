###!

###

'use strict';

angular.module('neo4jApp.services')
.service 'SojoboAuthService', [
  'ConnectionStatusService'
  'Server'
  'Settings'
  '$base64'
  '$q'
  (ConnectionStatusService, Server, Settings, $base64, $q) ->

    clearConnectionAuthData = ->
      ConnectionStatusService.clearConnectionAuthData()

    class SojoboAuthService
      constructor: ->

      authenticate: (username, password) ->
        if Settings.needAuthZ
          ConnectionStatusService.setConnectionAuthData(username, $base64.encode(username+":"+password))
          ConnectionStatusService.setConnected yes
        else
          ConnectionStatusService.setConnected yes

      hasValidAuthorization: ->
        if Settings.needAuthZ
          if ConnectionStatusService.connectedAsUser()
            ConnectionStatusService.setConnected yes
            return true
          else
            ConnectionStatusService.setConnected no
            return false
        else
          ConnectionStatusService.setConnected yes
          return true

      isConnected: ->
        ts = (new Date()).getTime()
        p = Server.status('?t='+ts)
        p.then(
          (rr) ->
            ConnectionStatusService.setConnected yes
            return true
          ,
          (rr) ->
            return false
        )

      forget: ->
        if ConnectionStatusService.connectedAsUser()
          clearConnectionAuthData()

      getCurrentUser: ->
        if Settings.needAuthZ
          ConnectionStatusService.connectedAsUser()
        else
          "dummy"

    new SojoboAuthService()
]
