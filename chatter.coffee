# Hubot dependencies
{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, Response} = require 'hubot'

jsforce = require 'jsforce'
require 'date-utils'

class ChatterAdapter extends Adapter
  constructor: (robot)->
    super robot
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
    
    @conn = new jsforce.Connection({
      version: @options.apiVersion
      loginUrl: @options.serverUrl
    })
  validate: ->
    if !@options.username || !@options.password
      @robot.logger.error "set username and password"
      process.exit 1
      return false

    if @options.pollingInterval < 5000
      @robot.logger.error "set HUBOT_SFDC_POLLING_INTERVAL larger than 5000:#{@options.pollingInterval}"
      process.exit 1
      return false
    if @options.pollingType == 'streaming' && !@options.topic
      @robot.logger.error "set topic when you set 'streaming' to polling type."
      peocess.exit 1
    return true
  run: ->
    if !@validate() then return
    @conn.login @options.username, @options.password, (err, userinfo)=>
      if err
        @robot.logger.error "#{err}"
        process.exit 1
        return
      if @options.parentId == ''
        @options.parentId = userinfo.id

      if @options.pollingType == 'streaming'
        @conn.streaming.topic(@options.topic).subscribe (res)=>
          record = res.sobject
          message = new TextMessage record.User__c, record.Body__c, "message-#{record.id}"
          message.room = record.ParentId__c
          message.type = @options.queryObject
          message.feedItemId = record.FeedItemId__c
          @receive message
      else if @options.pollingType == 'query'
        parentIds = @options.parentId.split(',').join("','")
        @setNewThreshold()
        @queryInterval = setInterval =>
          @robot.logger.info "polling query request..."
          @conn.query "#{@options.querybase} WHERE ParentId IN ('#{@parentIds}') AND CreatedDate > #{@threashold} ORDER BY CreatedDate", (err, result)=>
            if err
              @robot.logger.error "#{err}"
              process.exit 1
              return
            for record in result.records
              message = new TextMessage record.CreatedById, record.Body || record.CommentBody, "message-#{record.id}"
              message.room = record.ParentId
              message.type = @options.queryObject
              message.record = record
              message.replyParentId = record.FeedItemId
              @receive message
          @setNewThreshold()
        , @options.pollingInterval

    @emit 'connected'

  send: (envelope, strings...) =>
    for str in strings
      if envelope.message.replyParentId
        resource_path = "/feed-items/#{envelope.message.replyParentId}/comments"
      else
        resource_path = "/feeds/record/#{@options.parentId}/feed-items"

      chatterBody = {
        body: {
          messageSegments: [{
            type: 'Text'
            text: str
          }]
        }
      }
      if envelope.message.replyMensionUserId
        chatterBody.body.messageSegments.push {
          type: 'Mension'
          id: envelope.message.replyMensionUserId
        }
      @conn.chatter.resource(resource_path).create chatterBody, (err, result) =>
        if err
          @robot.logger.error "#{err}"
          process.exit 1

  reply: (envelope, strings...) ->
    for str in strings
      @send envelope, str

  setNewThreshold: ->
    @threashold = new Date().toUTCFormat("YYYY-MM-DDTHH24:MI:SS.000Z")

exports.use = (robot) ->
  new ChatterAdapter robot
