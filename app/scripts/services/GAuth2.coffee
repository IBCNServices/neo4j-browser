###

###

'use strict';

angular.module('neo4jApp.services')
  .service 'GAuth2', [
    'Settings'
    '$window'
    '$document'
    '$timeout'
    '$q'
    (Settings, $window, $document, $timeout, $q) ->
    
      LOAD_GAE_API = false
      LOADING_GAE_API = false
      URL = 'https://apis.google.com/js/client:platform.js?onload=_gapiOnLoad'
      OBSERVER_CALLBACKS = []
      auth2 = null
      
      loadScript = (src) ->
        deferred = $q.defer()
        $window._gapiOnLoad = () -> deferred.resolve()
        
        script = $document[0].createElement 'script'
        script.onerror = (e) -> $timeout (() -> deferred.reject(e))
        script.src = src
        $document[0].body.appendChild(script)
        console.log('loadScript')
        return deferred.promise
        
      return {
        get : () ->
          deferred = $q.defer()
          if (LOAD_GAE_API)
            deferred.resolve(auth2)
          else if (LOADING_GAE_API)
            OBSERVER_CALLBACKS.push(deferred)
          else
            LOADING_GAE_API = true
            loadScript(URL).then( () ->
              $window.gapi.load('auth2', () ->
                console.log("test")
                $window.gapi.auth2.init({
                  fetch_basic_profile: false
                  scope:'https://www.googleapis.com/auth/plus.login'
                }).then(() -> 
                  LOAD_GAE_API = true
                  LOADING_GAE_API = false
              
                  auth2 = $window.gapi.auth2.getAuthInstance()
                  deferred.resolve(auth2)
                  for oc in OBSERVER_CALLBACKS
                    oc.resolve(auth2)
                    
                  console.log("test2")
                )
              )
            )
          return deferred.promise
          
        
      }
  ]