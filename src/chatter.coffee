# Hubot dependencies
{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, Response} = require 'hubot'

jsforce = require 'jsforce'
dateformat = require 'dateformat'
time = require('time')(Date);

class SalesForceChatter extends Adapter
  run: ->
    # Client Options
    @options =
      username: process.env.HUBOT_SFDC_USERNAME
      password: process.env.HUBOT_SFDC_PASSWORD
      topic: process.env.HUBOT_SFDC_TOPIC
      apiVersion: process.env.HUBOT_SFDC_API_VERSION || '30.0'
      serverUrl: process.env.HUBOT_SFDC_LOGINURL || 'https://login.salesforce.com'
      pollingType: process.env.HUBOT_SFDC_POLLING_TYPE || 'query'
      queryObject: process.env.HUBOT_SFDC_QUERY_OBJECT || 'FeedItem'
      parentId: process.env.HUBOT_SFDC_PARENT_ID || ''
      pollingInterval: (process.env.HUBOT_SFDC_POLLING_INTERVAL || 60000)-0

    @options.querybase = do =>
        if @options.queryObject == 'FeedComment'
          return 'SELECT Id, CommentBody, ParentId, CreatedById, FeedItemId FROM FeedComment'
        else
          return 'SELECT Id, Body, ParentId, CreatedById FROM FeedItem'

    if !@options.username || !@options.password
      @robot.logger.error "set username and password"
      process.exit 1

    @conn = new jsforce.Connection({
      version: @options.apiVersion
      loginUrl: @options.serverUrl
    })
    @conn.login @options.username, @options.password, (err, userinfo)=>
      if err
        @robot.logger.error "#{err}"
        process.exit 1
      if @options.parentId == ''
        @options.parentId = userinfo.id

      if @options.pollingType == 'streaming'
        @conn.streaming.topic(@options.HUBOT_SFDC_TOPIC).subscribe (res)=>
          record = res.sobject
          message = new TextMessage record.User__c, record.Body__c, "message-#{record.id}"
          message.room = record.ParentId__c
          message.type = @options.queryObject
          message.feedItemId = record.FeedItemId__c
          @receive message
      else if @options.pollingType == 'query'
        @setNewThreshold()
        setInterval =>
          @robot.logger.info "polling query request..."
          @conn.query "#{@options.querybase} WHERE ParentId = '#{@options.parentId}' AND CreatedDate > #{@threashold} ORDER BY CreatedDate", (err, result)=>
            if err
              @robot.logger.error "#{err}"
              process.exit 1
            for record in result.records
              message = new TextMessage record.CreatedById, record.Body || record.CommentBody, "message-#{record.id}"
              message.room = record.ParentId
              message.type = @options.queryObject
              message.feedItemId = record.FeedItemId
              @receive message
          @setNewThreshold()
        , @options.pollingInterval

    @emit 'connected'

  send: (envelope, strings...) =>
    for str in strings
      if envelope.message.feedItemId
        resource_path = "/feed-items/#{envelope.message.feedItemId}/comments"
      else
        resource_path = "/feeds/record/#{@options.parentId}/feed-items"

      @conn.chatter.resource(resource_path).create {
        body: {
          messageSegments: [{
            type: 'Text'
            text: str
          }]
        }
      }, (err, result) =>
        if err
          @robot.logger.error "#{err}"
          process.exit 1

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope, str

  setNewThreshold: ->
    @threashold = dateformat(new Date().setTimezone('GMT'), "yyyy-mm-dd'T'HH:MM:ss.l'Z'")

exports.use = (robot) ->
  new SalesForceChatter robot
