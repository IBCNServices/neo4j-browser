###

###

'use strict';

angular.module('neo4jApp.services')
  .factory 'GAuth2', [
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
      profile = null
      token = null
      
      loadScript = (src) ->
        deferred = $q.defer()
        $window._gapiOnLoad = () -> deferred.resolve()
        script = $document[0].createElement 'script'
        script.onerror = (e) -> $timeout (() -> deferred.reject(e))
        script.src = src
        $document[0].body.appendChild(script)
        console.log('loadScript')
        return deferred.promise
        
      onSignIn = () ->
        console.log('signed in')
        user = auth2.currentUser.get()
        bp = user.getBasicProfile()
        profile = {
          name    : bp.getName()
          picture : bp.getImageUrl()
          email   : bp.getEmail()
        }
        token = user.getAuthResponse().id_token
        
      onSignOut = () ->
        console.log('signed out')
        auth2.signOut().then( () ->
          profile = null
          token = null
        )
        
      updateSignIn = () ->
        console.log('update sign in state')
        if (auth2.isSignedIn.get())
          CurrentUser.login()
        else
          CurrentUser.logout()
        
      _get = () ->
        q = $q.defer()
        if (LOAD_GAE_API)
          q.resolve("success: load_gae_api")
        else if (LOADING_GAE_API)
          OBSERVER_CALLBACKS.push(q)
        else
          LOADING_GAE_API = true
          loadScript(URL).then( () ->
            $window.gapi.load('auth2', () ->
              #$window.gapi.auth2.init({
              #  fetch_basic_profile: true
              #  scope:'https://www.googleapis.com/auth/plus.login'
              #}).then(() ->
              $window.gapi.auth2.init().then( () -> 
                LOAD_GAE_API = true
                LOADING_GAE_API = false
            
                auth2 = $window.gapi.auth2.getAuthInstance()
                #auth2.isSignedIn.listen(updateSignIn)
                #auth2.then(updateSignIn)
                q.resolve(true)
                for oc in OBSERVER_CALLBACKS
                  oc.resolve(true)
                  
                console.log("auth2 initialized")
              )
            )
          )
        return q.promise
      
      _login = ->
        q = $q.defer()
        _get().then( () ->
          if auth2.isSignedIn.get()
            console.log("Already Signed in.")
            onSignIn()
            q.resolve {
              profile    : profile
              token      : token
              data_token : token
            }
          else
            console.log("Not signed in.")
            q.reject "Not signed in."
        )
        q.promise
        
      _logout = ->
        q = $q.defer()
        _get().then( () ->
          auth2.signOut()
          onSignOut()
          q.resolve "Successfuly signed out."
        )
        q.promise
        
      _isSignedIn = ->
        q = $q.defer()
        _get().then( () -> q.resolve(auth2.isSignedIn.get()) )
        q.promise
          
      return {
        get    : _get  
        login  : _login
        logout : _logout
        isSignedIn : _isSignedIn
      }
  ]