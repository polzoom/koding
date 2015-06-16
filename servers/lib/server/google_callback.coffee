{
  redirectOauth
  saveOauthToSession
}                  = require './helpers'
{google}           = KONFIG
http               = require "https"
querystring        = require 'querystring'
provider           = "google"

module.exports = (req, res) ->
  access_token  = null
  refresh_token = null
  {code}        = req.query
  {clientId}    = req.cookies
  {
    client_id
    client_secret
    redirect_uri
  }            = google

  unless code
    redirectOauth res, {provider}, "No code in query"
    return

  # Get user info with access token
  fetchUserInfo = (userInfoResp)->
    rawResp = ""
    userInfoResp.on "data", (chunk) -> rawResp += chunk
    userInfoResp.on "end", ->
      try
        response = JSON.parse rawResp
        {id, email, given_name, family_name} = response
      catch e
        redirectOauth res, {provider}, "Error getting id"

      if id
        googleResp = {
          email
          token        : access_token
          foreignId    : id
          refreshToken : refresh_token
          expires      : new Date().getTime()+3600
          firstName    : given_name
          lastName     : family_name
          profile      : response
        }

        saveOauthToSession googleResp, clientId, provider, (err)->
          if err
            redirectOauth res, {provider}, "Error saving oauth info"
            return

          redirectOauth res, {provider}, null

  authorizeUser = (authUserResp)->
    rawResp = ""
    authUserResp.setEncoding('utf8')
    authUserResp.on "data", (chunk) -> rawResp += chunk
    authUserResp.on "end", ->
      try
        tokenInfo = JSON.parse rawResp
      catch e
        redirectOauth res, {provider}, "Error getting access token"

      {access_token, refresh_token} = tokenInfo
      if access_token
        options =
          host   : "www.googleapis.com"
          path   : "/oauth2/v2/userinfo?alt=json&access_token=#{access_token}"
          method : "GET"
        r = http.request options, fetchUserInfo
        r.end()
      else
        redirectOauth res, {provider}, "No access token"

  postData   = querystring.stringify {
    code,
    client_id,
    client_secret,
    redirect_uri,
    grant_type : "authorization_code"
  }

  options   =
    host    : "accounts.google.com"
    path    : "/o/oauth2/token"
    method  : "POST"
    headers : {
      'Content-Type'  : 'application/x-www-form-urlencoded'
      'Content-Length': postData.length,
      'Accept'        :'application/json'
    }

  r = http.request options, authorizeUser
  r.write postData
  r.end()

  r.on 'error', (e)-> console.error 'problem with request: ' + e.message
