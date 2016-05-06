###!

###

'use strict';

angular.module('neo4jApp.services')
.service 'GeniAuthService', [
  'ConnectionStatusService'
  'Server'
  'Settings'
  '$base64'
  '$q'
  (ConnectionStatusService, Server, Settings, $base64, $q) ->

    clearConnectionAuthData = ->
      ConnectionStatusService.clearConnectionAuthData()

    class GeniAuthService
      constructor: ->

      authenticate: (certificate) ->
        if Settings.needAuthZ
          ConnectionStatusService.setConnectionAuthData('localuser', $base64.encode(certificate))
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
        p = @makeRequest()
        p.then(
          (rr) ->
            ConnectionStatusService.setConnected yes
            return true
          ,
          (rr) ->
            return false
        )

      makeRequest: ->
        p = Server.get("#{Settings.endpoint.tengu}")
      
      forget: ->
        if ConnectionStatusService.connectedAsUser()
          clearConnectionAuthData()

      getCurrentUser: ->
        if Settings.needAuthZ
          ConnectionStatusService.connectedAsUser()
        else
          "dummy"

    new GeniAuthService()
]
