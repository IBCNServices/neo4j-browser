###!
Copyright (c) 2002-2014 "Neo Technology,"
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

'use strict';

angular.module('neo4jApp.services')
.service 'CurrentUser', [
  'Settings'
  'Editor'
  'localStorageService'
  'AuthDataService'
  '$q'
  '$window'
  '$rootScope'
  '$base64'
  '$http'
  'DefaultContentService'
  (Settings, Editor, localStorageService, AuthDataService, $q, $window, $rootScope, $base64, $http, DefaultContentService) ->

    #TODO: remove AuthDataService
    class CurrentUser
      _user: {}
      store: null

      getStoreCreds: ->
        local = localStorageService.get 'stores'
        local || []

      setStoreCreds: (creds_array) ->
        localStorageService.set 'stores', creds_array

      addCurrentStoreCreds: (id) ->
        creds = @getStoreCreds()
        current_creds = AuthDataService.getAuthData()
        return unless current_creds
        creds.push({store_id: id, creds: current_creds})
        @setStoreCreds creds

      removeCurrentStoreCreds: (id) ->
        creds = @getStoreCreds()
        for cred, i in creds
          if cred.store_id is id
            creds.splice i, 1
            break
        @setStoreCreds creds

      getCurrentStoreCreds: (id) ->
        creds = @getStoreCreds()
        for cred in creds
          if cred.store_id is id
            return cred
        return {}

      getToken: (id) ->
        return no unless id
        localStorageService.get "ntn_#{id}"

      loadUserFromLocalStorage: ->
        console.log("loadUserFromLocalStorage called")
        return unless @isAuthenticated()
        ##q = $q.defer()
        ##that = @
        @_user = localStorageService.get 'ntn_profile' || {}
        ##data_token = @getToken 'data_token'
        @store = no
        ###
        if @_user and data_token
          NTN.getUserStore(@_user.user_id, data_token).then(
            (store) ->
              that.store = store
              q.resolve()
              data = localStorageService.get 'ntn_profile' || {}
              $rootScope.$emit 'ntn:authenticated', 'yes', data
          )

        else
          q.resolve()
        ###
        $rootScope.$emit 'ntn:authenticated', 'yes', @_user
        ##q.promise

      getStore: ->
        that = @
        q = $q.defer()

        if @store && @store.getAuth()
          q.resolve @store
          return q.promise

        @refreshToken().then(
          q.resolve that.store
        )
        q.promise

      persist: (res) =>
        if res.token then localStorageService.set 'ntn_token', res.token
        if res.data_token then localStorageService.set 'ntn_data_token', res.data_token
        if res.profile then localStorageService.set 'ntn_profile', res.profile
        if res.refreshToken then localStorageService.set 'ntn_refresh_token', res.refreshToken
        @loadUserFromLocalStorage()

      clear: () ->
        localStorageService.clearAll()
        DefaultContentService.resetToDefault()
        #GraphStyle.resetToDefault()
        @loadUserFromLocalStorage()

      login: (username, password) ->
        q = $q.defer()

        authdata = "#{username}:#{password}"
        AuthDataService.setAuthData authdata
        basicAuth = $base64.encode(authdata)

        req = {
          "method"  : "POST"
          "url"     : Settings.endpoint.tengu + "/tengu/login"
          "headers"  : {
            "Content-Type"  : "application/json"
            "api-key"       : Settings.apiKey
            "Authorization" : "Basic " + basicAuth
          }
        }

        $http(req).then(
          (response) ->
            if response.status == 200
              res =
                token      : basicAuth
                data_token : basicAuth
                profile    :
                  name       : username
                  picture    : "/images/default_user.png"
                  email      : "dummy@tengu.io"

              cu.persist(res)
              data = localStorageService.get 'ntn_profile' || {}
              $rootScope.$emit 'ntn:login', data
              q.resolve(res)
          , (r) ->
            console.log(r)
            q.reject(r)
        )

        q.promise

      logout: ->
        q = $q.defer()
        $rootScope.currentUser = null
        localStorageService.remove 'ntn_token'
        localStorageService.remove 'ntn_data_token'
        localStorageService.remove 'ntn_refresh_token'
        localStorageService.remove 'ntn_profile'
        localStorageService.remove 'stores'

        AuthDataService.clearAuthData()
        cu.clear()
        $rootScope.$emit 'ntn:logout'
        q.resolve("CurrentUser cleaned up.")
        q.promise

      instance: -> angular.copy(@_user)

      isAuthenticated: -> localStorageService.get 'ntn_data_token'

      init: ->
        q = $q.defer()
        data = AuthDataService.getPlainAuthData()
        if data
          d = data.split(':')
          cu.login(d[0], d[1]).then( () ->
            q.resolve("CurrentUser logged in.")
          )
        else
          cu.logout().then( () ->
            q.reject("CurrentUser not logged in.")
          )
        q.promise


    cu = new CurrentUser
    cu
]
