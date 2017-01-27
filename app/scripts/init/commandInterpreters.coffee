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

angular.module('neo4jApp')
.config([
  'FrameProvider'
  'Settings'
  (FrameProvider, Settings) ->

    cmdchar = Settings.cmdchar

    # convert a string into a topical keyword
    topicalize = (input) ->
      if input?
        input.toLowerCase().trim().replace /\s+/g, '-'
      else
        null

    argv = (input) ->
      rv = input?.toLowerCase().split(' ')
      rv or []

    error = (msg, exception = "Error", data) ->
      errors: [
        message: msg
        code: exception
        data: data
      ]

    mapError = (r) ->
      if not r.errors
        returnObject = error("Error: #{r.raw.response.data.status} - #{r.raw.response.data.statusText}", 'Request error')
        r.errors = returnObject.errors
      r

    FrameProvider.interpreters.push
      type: 'clear'
      matches: "#{cmdchar}clear"
      exec: ['Frame', (Frame) ->
        (input) ->
          Frame.reset()
          true
      ]

    FrameProvider.interpreters.push
      type: 'style'
      matches: "#{cmdchar}style"
      exec: [
        '$rootScope', 'exportService', 'GraphStyle', '$http'
        ($rootScope, exportService, GraphStyle, $http) ->
          (input, q) ->
            switch argv(input)[1]
              when 'reset'
                GraphStyle.resetToDefault()
              when 'export'
                exportService.download('graphstyle.grass', 'text/plain;charset=utf-8', GraphStyle.toString())
              else
                clean_input = input[('style'.length+1)..].trim()
                if /^https?:\/\//i.test(clean_input)
                  $http.get(clean_input)
                  .then(
                    (res) ->
                      GraphStyle.importGrass(res.data)
                  ,
                    (r)->
                      console.log("failed to load grass, because ", r)
                  )
                else if clean_input.length > 0
                  GraphStyle.importGrass(clean_input)
                else
                  $rootScope.togglePopup('styling')
            true
      ]

    # Show command history
    FrameProvider.interpreters.push
      type: 'history'
      matches: "#{cmdchar}history"
      templateUrl: 'views/frame-history.html'
      exec: [
        'HistoryService',
        (HistoryService) ->
          (input, q) ->
            q.resolve(angular.copy(HistoryService.history))
            q.promise
      ]

    # FrameProvider.interpreters.push
    #   type: 'keys'
    #   templateUrl: 'views/frame-keys.html'
    #   matches: "#{cmdchar}keys"
    #   exec: ['$rootScope', ($rootScope) ->
    #     (input) -> true
    #   ]

    # Generic shell commands
    FrameProvider.interpreters.push
      type: 'shell'
      templateUrl: 'views/frame-rest.html'
      matches: "#{cmdchar}schema"
      exec: ['ProtocolFactory', (ProtocolFactory) ->
        (input, q) ->
          ProtocolFactory.getSchemaService().getSchema(input)
          .then(
            (res) ->
              q.resolve(res)
            ,
            (r) ->
              q.reject(r)
          )
          q.promise
      ]

    # play handler
    FrameProvider.interpreters.push
      type: 'play'
      templateUrl: 'views/frame-guide.html'
      matches: "#{cmdchar}play"
      exec: ['$http', '$rootScope', 'Utils', ($http, $rootScope, Utils) ->
        step_number = 1
        (input, q) ->
          clean_url = input[('play'.length+1)..].trim()
          is_remote = no
          if /^https?:\/\//i.test(clean_url)
            is_remote = yes
            url = input[('play'.length+2)..]
            host = url.match(/^(https?:\/\/[^\/]+)/)[1]
            host_ok = Utils.hostIsAllowed host, $rootScope.kernel['browser.remote_content_hostname_whitelist']
          else
            topic = topicalize(clean_url) or 'start'
            url = "content/guides/#{topic}.html"
          if is_remote and not host_ok
            q.reject({page: url, contents: '', is_remote: is_remote, errors: [{code: "0", message: "Requested host is not whitelisted in browser.remote_content_hostname_whitelist."}]})
            return q.promise
          $http.get(url)
          .then(
            (res) ->
              q.resolve({contents:res.data, page: url, is_remote: is_remote})
          ,
            (r)->
              r.is_remote = is_remote
              q.reject(r)
          )
          q.promise
      ]

    # Shorthand for ":play sysinfo"
    FrameProvider.interpreters.push
      type: 'play'
      matches: "#{cmdchar}sysinfo"
      exec: ['Frame', (Frame) ->
        (input, q) ->
          Frame.create {input: "#{Settings.cmdchar}play sysinfo"}
          return true
      ]

    # Help/man handler
    FrameProvider.interpreters.push
      type: 'help'
      templateUrl: 'views/frame-help.html'
      matches: ["#{cmdchar}help", "#{cmdchar}man"]
      exec: ['$http', ($http) ->
        (input, q) ->
          topic = topicalize(input[('help'.length+1)..]) or 'help'
          url = "content/help/#{topic}.html"
          $http.get(url)
          .then(
            ->
              q.resolve(page: url)
            ,
            (r)->
              q.reject(r)
          )
          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'config'
      templateUrl: 'views/frame-config.html'
      matches: ["#{cmdchar}config"]
      exec: ['Settings', 'SettingsStore', (Settings, SettingsStore) ->
        (input, q) ->
          # special command for reset
          if argv(input)[1] is "reset"
            SettingsStore.reset()
            q.resolve(Settings)
            return q.promise

          matches = /^[^\w]*config\s+([^:]+):?([\S\s]+)?$/.exec(input)
          if (matches?)
            [key, value] = [matches[1], matches[2]]
            if (value?)
              value = try eval(value)

              Settings[key] = value
              # Persist new config
              SettingsStore.save()
            else
              value = Settings[key]

            property = {}
            property[key] = value
            q.resolve(property)
          else
            q.resolve(Settings)

          q.promise

      ]

    # about handler
    # FrameProvider.interpreters.push
    #   type: 'info'
    #   templateUrl: 'views/frame-info.html'
    #   matches: "#{cmdchar}about"
    #   exec: ->
    #     (input, q) ->
    #       page: "content/help/about.html"

    # sysinfo handler
    # FrameProvider.interpreters.push
    #   type: 'info'
    #   templateUrl: 'views/frame-info.html'
    #   matches: "#{cmdchar}sysinfo"
    #   exec: ->
    #     (input, q) ->
    #       page: "content/guides/sysinfo.html"

    # HTTP Handler
    FrameProvider.interpreters.push
      type: 'http'
      templateUrl: 'views/frame-rest.html'
      matches: ["#{cmdchar}get", "#{cmdchar}post", "#{cmdchar}delete", "#{cmdchar}put", "#{cmdchar}head"]
      exec: ['Server', (Server) ->
        (input, q) ->
          regex = /^[^\w]*(get|GET|put|PUT|post|POST|delete|DELETE|head|HEAD)\s+(\S+)\s*([\S\s]+)?$/i
          result = regex.exec(input)

          try
            [verb, url, data] = [result[1], result[2], result[3]]
          catch e
            q.reject(error("Unparseable http request", 'Request error'))
            return q.promise

          verb = verb?.toLowerCase()
          if not verb
            q.reject(error("Invalid verb, expected 'GET, PUT, POST, HEAD or DELETE'", 'Request error'))
            return q.promise

          if not url?.length > 0
            q.reject(error("Missing path", 'Request error'))
            return q.promise

          if (verb is 'post' or verb is 'put')
            if data
              # insist that data is parseable JSON
              try
                JSON.parse(data.replace(/\n/g, ""))
              catch e
                q.reject(error("Payload does not seem to be valid data.", 'Request payload error'))
                return q.promise

          Server[verb]?(url, data)
          .then(
            (r) ->
              q.resolve(r.data)
            ,
            (r) ->
              q.reject(error("Error: #{r.status} - #{r.statusText}", 'Request error'))
          )

          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'auth'
      fullscreenable: false
      templateUrl: 'views/frame-geni-connect.html'
      matches: (input) ->
        pattern = new RegExp("^#{cmdchar}server connect")
        input.match(pattern)
      exec: ['GeniAuthService', (AuthService) ->
        (input, q) -> q.resolve()
      ]

    FrameProvider.interpreters.push
      type: 'auth'
      fullscreenable: false
      templateUrl: 'views/frame-geni-disconnect.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}server disconnect")
        input.match(pattern)
      exec: ['Settings', 'GeniAuthService', (Settings, AuthService) ->
        (input, q) ->
          q.resolve()
      ]

    FrameProvider.interpreters.push
      type: 'auth'
      fullscreenable: false
      templateUrl: 'views/frame-server-status.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}server status")
        input.match(pattern)
      exec: ['AuthService', 'ConnectionStatusService', (AuthService, ConnectionStatusService) ->
        (input, q) ->
          AuthService.hasValidAuthorization()
          .then(
            (r) ->
              q.resolve r
            ,
            (r) ->
              q.reject r
            )
          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'auth'
      fullscreenable: false
      templateUrl: 'views/frame-change-password.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}server change-password")
        input.match(pattern)
      exec: ['AuthService', (AuthService) ->
        (input, q) ->
          q.resolve()
          q.promise
      ]


    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-login.html'
      matches: ["#{cmdchar}login"]
      exec: ['CurrentUser', '$rootScope', (CurrentUser, $rootScope) ->
        (input, q) ->
          CurrentUser.login()
          .then(->
            q.resolve(CurrentUser.instance())
          , ->
            q.reject("Unable to log in")
          )
          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-logout.html'
      matches: ["#{cmdchar}logout"]
      exec: ['CurrentUser', (CurrentUser) ->
        (input, q) ->
          CurrentUser.logout()
          q.resolve()
          q.promise
      ]

    extractGraphModel = (response, CypherGraphModel) ->
      graph = new neo.models.Graph()

      nodes = response.nodes.reduce((all, curr) -> # Only count unique nodes
        return all if all.taken.indexOf(curr.id) > -1
        all.nodes.push(curr)
        all.taken.push(curr.id)
        return all
      , {nodes: [], taken: []}).nodes

      if nodes.length > Settings.initialNodeDisplay
        nodes = nodes.slice(0, Settings.initialNodeDisplay)
        graph.display =
          initialNodeDisplay: Settings.initialNodeDisplay
          nodeCount: response.size
      nodes = nodes
        .map(CypherGraphModel.convertNode())
        .filter((node)-> return node)
      graph.addNodes(nodes)
      graph.addRelationships(CypherGraphModel.filterRelationshipsOnNodes(response.relationships, nodes)
        .map(CypherGraphModel.convertRelationship(graph))
        .filter((rel)-> return rel))
      graph

    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-tengu-sign-in.html'
      matches: ["#{cmdchar}signin"]
      exec: ['SojoboAuthService', (AuthService) ->
        (input, q) ->
          q.resolve(AuthService.hasValidAuthorization)
          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-tengu-sign-out.html'
      matches: ["#{cmdchar}signout"]
      exec: ['SojoboAuthService', (AuthService) ->
        (input, q) ->
          q.resolve(not AuthService.hasValidAuthorization)
          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-tengu-userinfo.html'
      matches: (input) ->
        pattern = new RegExp("^#{cmdchar}tengu user-info")
        input.match(pattern)
      exec: ['SojoboAuthService', 'ConnectionStatusService', 'Settings', '$http', (AuthService, ConnectionStatusService, Settings, $http) ->
        (input, q) ->
          if AuthService.hasValidAuthorization
            static_user = ConnectionStatusService.plainConnectionAuthData()[0]
            url = Settings.endpoint.tengu + "/users/" + static_user
            basicAuth = ConnectionStatusService.plainConnectionAuthData()[1]

            req = {
              "method"  : "GET"
              "url"     : url
              "headers"  : {
                "Content-Type"  : "application/json"
                "api-key"       : Settings.apiKey
                "Authorization" : "Basic " + basicAuth
              }
            }

            $http(req).then(
              (response) ->
                q.resolve(
                  userinfo : response.data
                )
              , (r) ->
                console.log(r)
                q.reject("Unknown error: [" + r.status + ", " + statusText + "] ")
            )
          else
            Frame.createOne({input:"#{cmdchar}signin"})
            q.reject("User is not authorized.")

          q.promise
      ]

    FrameProvider.interpreters.push
      type: 'account'
      templateUrl: 'views/frame-tengu-changepassword.html'
      matches: (input) ->
        pattern = new RegExp("^#{cmdchar}tengu change-user-password")
        input.match(pattern)
      exec: ['SojoboAuthService', 'ConnectionStatusService', 'Settings', '$http', (AuthService, ConnectionStatusService, Settings, $http) ->
        (input, q) ->
          if AuthService.hasValidAuthorization
            q.resolve("User authorized.")
          else
            Frame.createOne({input:"#{cmdchar}signin"})
            q.reject("User is not authorized.")

          q.promise
      ]

    # Tengu model create handler
    FrameProvider.interpreters.push
      type: 'tengu'
      templateUrl: 'views/frame-model-create.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}tengu model create")
        input.match(pattern)
      exec: ['SojoboAuthService', 'Frame', 'Settings', '$http', (AuthService, Frame, Settings, $http) ->
        (input, q) ->
          bundleI = input.indexOf('--bundle')
          if bundleI > 0
            bundle = input[(bundleI+'--bundle'.length+1)..].trim()
            modelName = input[('tengu model create'.length+1)..(bundleI-1)].trim() or ''
          else
            bundle = null
            modelName = input[('tengu model create'.length+1)..].trim() or ''

          if AuthService.hasValidAuthorization()
            if modelName? and modelName.length > 0
              modAndCtrl = modelName.split('@')
              if modAndCtrl.length > 1
                modelName = modAndCtrl[0]
                controller = modAndCtrl[1]
              else
                q.reject("If you provide the name of the model, you should also provide the Controller's name: <model>@<controller>")
                return q.promise
            else
              modelName = null
              controller = null

            if bundle?
              if bundle.startsWith('http')
                url = bundle
              else
                url = Settings.endpoint.bundles.replace('{{bundlename}}', bundle)
              console.log url
              req = {
                "method"  : "GET"
                "url"     : url
              }
              $http(req).then(
                (response) ->
                  console.log response
                  q.resolve(
                    modelName  : modelName
                    controller : controller
                    bundle     : response.data
                  )
                , (r) ->
                  if r.status = 404
                    q.reject("Could not find the Bundle '" + bundle + "'")
                  else
                    console.log(r)
                    q.reject("Unknown error: [" + r.status + ", " + r.statusText + "] ")
              )
            else
              q.resolve(
                modelName  : modelName
                controller : controller
              )
          else
            Frame.createOne({input:"#{cmdchar}signin"})
            q.reject("User is not authorized to create Models.")

          q.promise
      ]

    # Tengu model delete handler
    FrameProvider.interpreters.push
      type: 'tengu'
      templateUrl: 'views/frame-model-delete.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}tengu model delete")
        input.match(pattern)
      exec: ['SojoboAuthService', 'ConnectionStatusService', 'Settings', '$http', (AuthService, ConnectionStatusService, Settings, $http) ->
        (input, q) ->
          modelName = topicalize(input[('tengu model delete'.length+1)..]) or 'blank'
          if !AuthService.hasValidAuthorization()
            Frame.createOne({input:"#{cmdchar}signin"})
            q.reject("User is not authorized to talk to the Sojobo.")
          else if modelName == 'blank'
            q.reject("User must provide the name of the Model.")
          else
            modAndCtrl = modelName.split('@')
            if modAndCtrl.length > 1
              q.resolve(
                modelName  : modAndCtrl[0]
                controller : modAndCtrl[1]
              )
            else
              q.resolve(
                modelName  : modelName
              )

          q.promise
      ]

    # Tengu model status handler
    FrameProvider.interpreters.push
      type: 'tengu'
      templateUrl: 'views/frame-model-status.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}tengu model status")
        input.match(pattern)
      exec: ['SojoboAuthService', 'ConnectionStatusService', 'Settings', '$http', (AuthService, ConnectionStatusService, Settings, $http) ->
        (input, q) ->
          modelName = topicalize(input[('tengu model status'.length+1)..]) or 'blank'
          if !AuthService.hasValidAuthorization()
            Frame.createOne({input:"#{cmdchar}signin"})
            q.reject("User is not authorized to check the status of a Model.")
          else if modelName == 'blank'
            q.reject("User must provide the name of the Model.")
          else
            modAndCtrl = modelName.split('@')
            if modAndCtrl.length > 1
              url = Settings.endpoint.tengu + "/tengu/controllers/" + modAndCtrl[1] + "/models/" + modAndCtrl[0]
            else
              url = Settings.endpoint.tengu + "/tengu/controllers/" + Settings.sojobo_controller + "/models/" + modelName

            basicAuth = ConnectionStatusService.plainConnectionAuthData()[1]

            console.log url

            req = {
              "method"  : "GET"
              "url"     : url
              "headers"  : {
                "Content-Type"  : "application/json"
                "api-key"       : Settings.apiKey
                "Authorization" : "Basic " + basicAuth
              }
            }

            $http(req).then(
              (response) ->
                if modAndCtrl.length > 1
                  q.resolve(
                    modelName  : modAndCtrl[0]
                    controller : modAndCtrl[1]
                    data       : response.data
                    req        : req
                  )
                else
                  q.resolve(
                    modelName: modelName
                    data     : response.data
                    req      : req
                  )
              , (r) ->
                if r.status = 404
                  console.log(r.data.msg)
                  q.reject("Could not find the Model '" + modelName + "'")
                else
                  console.log(r)
                  q.reject("Unknown error: [" + r.status + ", " + statusText + "] ")
            )

          q.promise
      ]

    # Tengu console handler
    FrameProvider.interpreters.push
      type: 'tengu'
      templateUrl: 'views/frame-console.html'
      matches:  (input) ->
        pattern = new RegExp("^#{cmdchar}tengu console")
        input.match(pattern)
      exec: ['GeniAuthService', 'ConnectionStatusService', 'Settings', '$http', (GeniAuthService, ConnectionStatusService, Settings, $http) ->
        (input, q) ->
          hauchiwa = topicalize(input[('tengu console'.length+1)..]) or 'blank'
          if hauchiwa != 'blank'
            req = {
              "method"  : "GET"
              "url"     : Settings.endpoint.tengu + "/" + Settings.sojobo_models[0] + "/" + hauchiwa
              "headers" : { "emulab-s4-cert" : ConnectionStatusService.plainConnectionAuthData()[1] }
            }

            $http(req).then(
              (response) ->
                q.resolve(
                  hauchiwa: hauchiwa
                  console_url: "https://n097-18b.wall2.ilabt.iminds.be:3000/"
                )
              , (r) ->
                q.reject(r)
            )
          else
            q.reject('no hauchiwa provided')

          q.promise
      ]

])
