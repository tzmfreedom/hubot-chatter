{Robot} = require("hubot")

class MockRobot extends Robot
    constructor : (adapter) ->
        super "", adapter, false, "Hubot" 
    loadAdapter : (path, adapter) ->
        @adapter = adapter.use @

module.exports = MockRobot