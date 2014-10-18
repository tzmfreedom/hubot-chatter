ChatterAdapter = require("../")
{Robot} = require("hubot")
MockRobot = require("./mock/robot")
sinon = require("sinon")
require("date-utils")

process.env.HUBOT_SFDC_USERNAME = 'user@example.com'
process.env.HUBOT_SFDC_PASSWORD = 'hogefuga'

robot = new MockRobot(ChatterAdapter)
adapter = robot.adapter

describe "hubot-chatter", ->
  loginCallback = {}
  queryCallback = {}
  streamingCallback = {}
  createCallback = {}
  it "should call login method when robot runs.", (done)->
    login = sinon.stub adapter.conn, "login", (username, password, callback)->
      expect(username).toBe(process.env.HUBOT_SFDC_USERNAME)
      expect(password).toBe(process.env.HUBOT_SFDC_PASSWORD)
      loginCallback = callback
      adapter.conn.login.restore() 
      adapter.options.pollingInterval = 100
      done()
    robot.run()

  it "shold call process.exit when login failure.", (done)->
    exit = sinon.stub process, "exit", (status)->
      expect(status).toBe(1)
    sinon.stub robot.logger, "error", (message)->
      expect(message).toBe("error")
      robot.logger.error.restore()
    loginCallback "error", {}
    process.exit.restore()
    done()

  it "should call query when login successful.", (done)->
    query = sinon.stub adapter.conn, "query", (soql, callback)->
      clearInterval adapter.queryInterval
      queryCallback = callback
      adapter.conn.query.restore()
      done()
    loginCallback(undefined, { id : "005xxxxxxxxxxxx"})

  it "should call receive when query one record successful.", (done)->
    receive = sinon.spy(adapter, "receive")
    response = {
      records: [
        { id : "AAAAA", Body: "hogehoge", ParentId: "BBBB", CreatedById: "CCCCC"}
      ]
    }
    queryCallback(undefined, response)
    expect(receive.calledOnce).toBe(true)
    record = response.records[0];
    expect(receive.getCall(0).args[0].user).toBe(record.CreatedById)
    expect(receive.getCall(0).args[0].text).toBe(record.Body)
    expect(receive.getCall(0).args[0].id).toBe("message-#{record.id}")
    expect(receive.getCall(0).args[0].room).toBe(record.ParentId)
    expect(receive.getCall(0).args[0].type).toBe(adapter.options.queryObject)
    expect(receive.getCall(0).args[0].feedItemId).toBe(undefined)
    adapter.receive.restore()
    done()

  it "should call receive when query many record successful.", (done)->
    receive = sinon.spy(adapter, "receive")
    response = {
      records: [
        { id : "AAAAA1", Body: "hogehoge1", ParentId: "BBBB1", CreatedById: "CCCCC1"},
        { id : "AAAAA2", Body: "hogehoge2", ParentId: "BBBB2", CreatedById: "CCCCC2"},
        { id : "AAAAA3", Body: "hogehoge3", ParentId: "BBBB3", CreatedById: "CCCCC3"}
      ]
    }
    queryCallback(undefined, response)
    expect(receive.callCount).toBe(3)
    for i in [0..2]
      record = response.records[i]
      expect(receive.getCall(i).args[0].user).toBe(record.CreatedById)
      expect(receive.getCall(i).args[0].text).toBe(record.Body)
      expect(receive.getCall(i).args[0].id).toBe("message-#{record.id}")
      expect(receive.getCall(i).args[0].room).toBe(record.ParentId)
      expect(receive.getCall(i).args[0].type).toBe(adapter.options.queryObject)
      expect(receive.getCall(i).args[0].feedItemId).toBe(undefined)
    adapter.receive.restore()
    done()

  it "should call process.exit when query failure.", (done)->
    spy = sinon.stub process, "exit", (status)->
      expect(status).toBe(1)
      process.exit.restore()
    sinon.stub robot.logger, "error", (message)->
      expect(message).toBe("error")
      robot.logger.error.restore()
    queryCallback "error", {}
    expect(spy.calledOnce).toBe(true)
    clearInterval robot.brain.saveInterval
    done()

  it "should call streamingAPI when login successful.", (done)->
    topic = sinon.stub adapter.conn.streaming, "topic", (topic)->
      return {
        subscribe: (callback)->
          streamingCallback = callback
          adapter.conn.streaming.topic.restore()
          done()
      }

    adapter.options.pollingType = 'streaming'
    adapter.options.topic = 'hogetopic'
    loginCallback(undefined, { id : "005xxxxxxxxxxxx"})

  it "should call receive when streamingAPI succesful", (done)->
    receive = sinon.spy(adapter, "receive")
    response = {
      sobject: {
        id: "id"
        User__c: "u"
        Body__c: "b"
        ParentId__c: "p"
        FeedItemId__c: "f"
      }
    }
    streamingCallback(response)
    expect(receive.calledOnce).toBe(true)
    record = response.sobject
    expect(receive.getCall(0).args[0].user).toBe(record.User__c)
    expect(receive.getCall(0).args[0].text).toBe(record.Body__c)
    expect(receive.getCall(0).args[0].id).toBe("message-#{record.id}")
    expect(receive.getCall(0).args[0].room).toBe(record.ParentId__c)
    expect(receive.getCall(0).args[0].type).toBe(adapter.options.queryObject)
    expect(receive.getCall(0).args[0].feedItemId).toBe(record.FeedItemId__c)
    adapter.receive.restore()
    done()

  it "should call create feeditem when send message", (done)->
    sinon.stub adapter.conn.chatter, "resource", (resource)->
      expect(resource).toBe("/feeds/record/#{adapter.options.parentId}/feed-items")
      return {
        create: (chatterBody, callback)->
          expect(chatterBody.body.messageSegments[0].type).toBe("Text")
          expect(chatterBody.body.messageSegments[0].text).toBe("hogemessage")
          adapter.conn.chatter.resource.restore()
          createCallback = callback
          done()
      }
    adapter.send {message: {feedItem: ""}}, "hogemessage"

  it "should call create feedcomment when send message", (done)->
    sinon.stub adapter.conn.chatter, "resource", (resource)->
      expect(resource).toBe("/feed-items/hogefeedcomment/comments")
      return {
        create: (chatterBody, callback)->
          message = envelope.message
          expect(chatterBody.body.messageSegments[0].type).toBe("Text")
          expect(chatterBody.body.messageSegments[0].text).toBe(textmessage)
          adapter.conn.chatter.resource.restore()
          createCallback = callback
          done()
      }
    envelope = {
      message: {
        feedItem: ""
        replyParentId: "hogefeedcomment"
      }
    }
    textmessage = "hogemessage"
    adapter.send envelope, textmessage

  it "should call create feeditem with mension when send message", (done)->
    sinon.stub adapter.conn.chatter, "resource", (resource)->
      return {
        create: (chatterBody, callback)->
          message = envelope.message
          expect(chatterBody.body.messageSegments[0].type).toBe("Text")
          expect(chatterBody.body.messageSegments[0].text).toBe(textmessage)
          expect(chatterBody.body.messageSegments[1].type).toBe("Mension")
          expect(chatterBody.body.messageSegments[1].id).toBe(message.replyMensionUserId)
          adapter.conn.chatter.resource.restore()
          createCallback = callback
          done()
      }
    envelope = {
      message: {
        feedItem: ""
        replyMensionUserId: "mension"
      }
    }
    textmessage = "hogemessage"
    adapter.send  envelope, textmessage

  it "should call process.exit when credentials are not set.", (done)->
    exit = sinon.stub process, "exit", (status)->
      expect(status).toBe(1)
      process.exit.restore()
      done()
    process.env.HUBOT_SFDC_USERNAME = ''
    process.env.HUBOT_SFDC_PASSWORD = ''
    robot = new MockRobot(ChatterAdapter)
    adapter = robot.adapter
    sinon.stub robot.logger, "error", (message)->
      expect(message).toBe("set username and password")
    robot.run()
    clearInterval robot.brain.saveInterval