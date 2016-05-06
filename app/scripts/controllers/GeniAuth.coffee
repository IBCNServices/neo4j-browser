###!

###

'use strict'

angular.module('neo4jApp.controllers')
  .controller 'GeniAuthCtrl', [
    '$scope'
    'GeniAuthService'
    'ConnectionStatusService'
    'Frame'
    'Settings'
    '$timeout'
    ($scope, GeniAuthService, ConnectionStatusService, Frame, Settings, $timeout) ->
      $scope.username = 'localuser'
      $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
      $scope.static_user = $scope.connection_summary.user
      $scope.static_is_authenticated = $scope.connection_summary.is_connected
      $scope.policy_message = ''

      genilib.trustedHost = 'https://authority.ilabt.iminds.be'
      genilib.trustedPath = '/speaks-for/xml-signer/index.html'

      #myId = 'urn:publicid:IDN+wall2.ilabt.iminds.be+user+tengujfed'
      myId = 'urn:publicid:IDN+wall2.ilabt.iminds.be+user+tengu'

      ###
      myCert = "-----BEGIN CERTIFICATE-----\n\
MIIEDDCCA3WgAwIBAgIDAZZZMA0GCSqGSIb3DQEBBAUAMIG1MQswCQYDVQQGEwJC\
RTELMAkGA1UECBMCT1YxDjAMBgNVBAcTBUdoZW50MRgwFgYDVQQKEw9pTWluZHMg\
LSBpbGFiLnQxHjAcBgNVBAsTFUNlcnRpZmljYXRlIEF1dGhvcml0eTEjMCEGA1UE\
AxMaYm9zcy53YWxsMi5pbGFidC5pbWluZHMuYmUxKjAoBgkqhkiG9w0BCQEWG3Z3\
YWxsLW9wc0BhdGxhbnRpcy51Z2VudC5iZTAeFw0xNTA2MDkwMTIyNThaFw0xNjA2\
MDgwMTIyNThaMIGyMQswCQYDVQQGEwJCRTELMAkGA1UECBMCT1YxGDAWBgNVBAoT\
D2lNaW5kcyAtIGlsYWIudDEeMBwGA1UECxMVaW1pbmRzLXdhbGwyLnRlbmdqZmVk\
MS0wKwYDVQQDEyRjNWVmNDg5Ni0wZTQ1LTExZTUtYmQ5Zi0wMDE1MTdiZWNkYzEx\
LTArBgkqhkiG9w0BCQEWHnRlbmdqZmVkQHdhbGwyLmlsYWJ0LmltaW5kcy5iZTCB\
nzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAu1wJ1RyQqwbuV2KC165m/MqM0CYW\
iHLEa95cU7YrXPQKsUN0oAWhMobhymMteN7OuQGrWSi6Iy8viV9DnbKOoUQqVzwJ\
AT0cuAj+/IP7vLwL6KqFM7Me/2BtrPLFHk0Q7Dah6Kr0EFM4L/hkrlr8Sm+jjrTe\
KWy18Ill8ub8QMcCAwEAAaOCASkwggElMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYE\
FBk6RbtCdFUGyHrRgq7i9QF6VqHPMIGQBgNVHREEgYgwgYWGNHVybjpwdWJsaWNp\
ZDpJRE4rd2FsbDIuaWxhYnQuaW1pbmRzLmJlK3VzZXIrdGVuZ2pmZWSBHnRlbmdq\
ZmVkQHdhbGwyLmlsYWJ0LmltaW5kcy5iZYYtdXJuOnV1aWQ6YzVlZjQ4OTYtMGU0\
NS0xMWU1LWJkOWYtMDAxNTE3YmVjZGMxMGMGCCsGAQUFBwEBBFcwVTBTBhRpg8yT\
gKiYzKjHvbGngICqrteKG4Y7aHR0cHM6Ly93d3cud2FsbDIuaWxhYnQuaW1pbmRz\
LmJlOjEyMzY5L3Byb3RvZ2VuaS94bWxycGMvc2EwDQYJKoZIhvcNAQEEBQADgYEA\
Gha5Ww7x5CgYJZ7tLP6xeMgfhqdzg+/fjrlWWi+9uyOB2XqZOYyEs05x8BlOPIzg\
vhGd2XJLZc4y9exRkQSo0OTouIn8Zzj5Xkdf/Qv00dNr7MN16JoO70Hp05aKnawW\
GF7cEjMOMaT1jrxf+xMbw8HJWTksP+ngnQKFAeDWDnQ=\n\
-----END CERTIFICATE-----"
      ###
      myCert = "-----BEGIN CERTIFICATE-----\n\
MIID/zCCA2igAwIBAgIDAvnAMA0GCSqGSIb3DQEBBAUAMIG1MQswCQYDVQQGEwJC\
RTELMAkGA1UECBMCT1YxDjAMBgNVBAcTBUdoZW50MRgwFgYDVQQKEw9pTWluZHMg\
LSBpbGFiLnQxHjAcBgNVBAsTFUNlcnRpZmljYXRlIEF1dGhvcml0eTEjMCEGA1UE\
AxMaYm9zcy53YWxsMi5pbGFidC5pbWluZHMuYmUxKjAoBgkqhkiG9w0BCQEWG3Z3\
YWxsLW9wc0BhdGxhbnRpcy51Z2VudC5iZTAeFw0xNjA0MTQyMTI4NTRaFw0xNzA0\
MTQyMTI4NTRaMIGsMQswCQYDVQQGEwJCRTELMAkGA1UECBMCT1YxGDAWBgNVBAoT\
D2lNaW5kcyAtIGlsYWIudDEbMBkGA1UECxMSaW1pbmRzLXdhbGwyLnRlbmd1MS0w\
KwYDVQQDEyRjMjQxODg1Ny04OWQzLTExZTQtYmQ5Zi0wMDE1MTdiZWNkYzExKjAo\
BgkqhkiG9w0BCQEWG3Rlbmd1QHdhbGwyLmlsYWJ0LmltaW5kcy5iZTCBnzANBgkq\
hkiG9w0BAQEFAAOBjQAwgYkCgYEA6QAqmbkYod1dpxtw096OooMj1Q6utRcripGy\
ZAiyV96zETVMAf0xxmMZWpSWmdk0JXIfpycoA4D9BxGWCmBNnTTkeQnnFtnt520a\
1s8TJVSVezeezCAOVctHpEEY3f3k5KR4oYVq/Gd6iqB9eShKFlXtnMC83tqXQ44Q\
l4pEyxMCAwEAAaOCASIwggEeMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFEdT0MG6\
vC0snJq2ErkwCxk0/H2dMIGJBgNVHREEgYEwf4YxdXJuOnB1YmxpY2lkOklETit3\
YWxsMi5pbGFidC5pbWluZHMuYmUrdXNlcit0ZW5ndYEbdGVuZ3VAd2FsbDIuaWxh\
YnQuaW1pbmRzLmJlhi11cm46dXVpZDpjMjQxODg1Ny04OWQzLTExZTQtYmQ5Zi0w\
MDE1MTdiZWNkYzEwYwYIKwYBBQUHAQEEVzBVMFMGFGmDzJOAqJjMqMe9saeAgKqu\
14obhjtodHRwczovL3d3dy53YWxsMi5pbGFidC5pbWluZHMuYmU6MTIzNjkvcHJv\
dG9nZW5pL3htbHJwYy9zYTANBgkqhkiG9w0BAQQFAAOBgQAG19WuyLVpEOxobJ0Q\
5b98Tv4dgDwuvukGOMmnsKMOIc9jnq3AUUWZg40rGiIWrW6gGrl66aNg8QukGW4l\
YvM6CenjwwU3+gFpr2Hcgw4WXA0CYD/icgm7jEnO8GFH7c3UOtaxVkuFIR3aaOuP\
fGFGFCN5Lpw8lIC+gb4unBneng==\n\
-----END CERTIFICATE-----"

      setPolicyMessage = ->
        return unless $scope.static_is_authenticated
        _connection_summary = ConnectionStatusService.getConnectionStatusSummary()
        if _connection_summary.credential_timeout is null
          $timeout(->
            setPolicyMessage()
          , 1000)
          return
        msg = ""
        if _connection_summary.store_credentials
          msg += "Connection credentials are stored in your web browser"
        else
          msg += "Connection credentials are not stored in your web browser"
        if _connection_summary.credential_timeout > 0
          msg += " and your credential timeout when idle is #{_connection_summary.credential_timeout} seconds."
        else
          msg += "."
        $scope.$evalAsync(->
          $scope.policy_message = msg
        )

      complete = (cert) ->
        GeniAuthService.authenticate(cert)
        $scope.frame.resetError()
        $scope.connection_summary = ConnectionStatusService.getConnectionStatusSummary()
        $scope.static_user = $scope.connection_summary.user
        $scope.static_is_authenticated = $scope.connection_summary.is_connected
        setPolicyMessage()
        Frame.create({input:"#{Settings.initCmd}"})
        $scope.focusEditor()

      $scope.authenticate = (event) ->
        $scope.frame.resetError()
        genilib.authorize(myId, myCert, complete)
        return false;

      setPolicyMessage()
  ]
