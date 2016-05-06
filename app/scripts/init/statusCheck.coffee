###!
Copyright (c) 2002-2016 "Neo Technology,"
Network Engine for Objects in Lund AB [http://neotechnology.com]

This file is part of Neo4j.

Neo4j is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

angular.module('neo4jApp').run([
  'GeniAuthService'
  '$rootScope'
  '$timeout'
  'Server'
  'Settings'
  'SettingsStore'
  (AuthService, $scope, $timeout, Server, Settings, SettingsStore) ->
    timer = null

    error = (multiplier) ->
      $scope.offline = yes
      $scope.unauthorized = no
      timer = $timeout($scope.check, multiplier * 1000)

    $scope.check = ->
      $timeout.cancel(timer)
      # There is something wrong with the XHR implementation in IE10:
      # It will return 304 (not modified) even if the server goes down as long as
      # the URL is the same. So we need a unique URL every time in order for it
      # to detect request error
      ts = (new Date()).getTime()
      Server.status('?t='+ts).success(
        (r) ->
          $scope.offline = no
          if r.models? and r.name?
            Settings.sojobo_models = r.models
            if r.name.toLowerCase().indexOf("sojobo")
              Settings.useSojobo = yes
            else if r.name.toLowerCase().indexOf("hauchiwa")
              Settings.useSojobo = no
            else
              error(Settings.offline_heartbeat)
              return r
            timer = $timeout($scope.check, Settings.heartbeat * 1000)
            SettingsStore.save()
          else
            error(Settings.offline_heartbeat)
            return r
          r
      ).error(
        (r) ->
          error(2)
          r
      )
      ###
      No authorization is not always a problem in Tengu
      .then(
        (r) ->
          AuthService.isConnected().then(
            ->
              $scope.unauthorized = no
          ,
            (response) ->
              if response.status in [401, 403, 429]
                $scope.offline = no
                $scope.unauthorized = yes
              else
                $scope.offline = yes
                $scope.unauthorized = no
          ).then(-> $scope.refresh() )
          r
      )
      ###
    $timeout($scope.check, 20000)
])
