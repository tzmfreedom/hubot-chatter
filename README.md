# Hubot Chatter Adapter
## Description
This is [Chatter](http://www.salesforce.com/jp/chatter/overview/) adapter for hubot.

## Installation and Setup
1. Add hubot-chatter to dependencies in your hubot's package.json.
```json
"dependencies": {
        "hubot-chatter": "1.0.0",
        "hubot": "~2.8.2"
}
```

2. Install hubot-chatter
```bash
npm install
```

3. Set environment variables.
``` bash
export HUBOT_SFDC_USERNAME="input hubot user's username"
export HUBOT_SFDC_PASSWORD="input hubot user's password"
```

4. Run hubot with chatter adapter.
```bash
bin/hubot -a chatter
```

## Usage
The chatter adapter requires only the following environment variables.

* HUBOT_SFDC_USERNAME
* HUBOT_SFDC_PASSWORD

And the following are optional.

* HUBOT_SFDC_LOGINURL
* HUBOT_SFDC_API_VERSION
* HUBOT_SFDC_QUERY_OBJECT
* HUBOT_SFDC_POLLING_TYPE
* HUBOT_SFDC_TOPIC
* HUBOT_SFDC_POLLING_INTERVAL
* HUBOT_SFDC_PARENT_ID

#### HUBOT_SFDC_USERNAME
This is the username for your chatter bot.

#### HUBOT_SFDC_PASSWORD
This is the password for your chatter bot.

#### HUBOT_SFDC_LOGINURL
This is the salesforce login server URL(e.g. 'https://login.salesforce.com/')  
If not specified, this value defaults to "https://login.salesforce.com".  
Set to "https://test.salesforce.com", when you want your hubot to connect to sandbox.

#### HUBOT_SFDC_API_VERSION
This is the salesforce API version.  
If not specified, this value defaults to "30.0".

#### HUBOT_SFDC_QUERY_OBJECT
This is the chatter object which you want to monitor and post.

#### HUBOT_SFDC_POLLING_TYPE
This is the method for monitoring chatter objects.  
Set to "streaming", when you want to use StreamingAPI to monitor chatter objects.  
Set to "query", when you want to use SOQL and polling to monitor chatter objects.  
If not specified, this value defaults to "query".

#### HUBOT_SFDC_TOPIC
This is the topic name to subscribe for StreamingAPI.  
Set to the target topic name, when you want to use StreamingAPI (HUBOT_SFDC_POLLING_TYPE='streaming').

#### HUBOT_SFDC_PARENT_ID
This is the parent ID which your hubot moniters and posts feeds to(e.g. Chatter Group ID).  
If not specified, your hubot monitors and posts feeds to user account(refered by HUBOT_SFDC_USERNAME).

#### HUBOT_SFDC_POLLING_INTERVAL
This is the number of milliseconds to wait between attempts when polling for results of the query result.  
If not specified, this value defaults to 60,000(1min).

## Sample

#### Using SOQL polling
```bash
export HUBOT_SFDC_USERNAME=user@example.com
export HUBOT_SFDC_PASSWORD=hogefuga
```

#### Using StreamingAPI
```bash
export HUBOT_SFDC_USERNAME=user@example.com
export HUBOT_SFDC_PASSWORD=hogefuga
export HUBOT_SFDC_POLLINGTYPE=streaming
export HUBOT_SFDC_TOPIC=AllMessages
```

#### Connect to Sandbox with setting to 5minutes for polling interval
```bash
export HUBOT_SFDC_USERNAME='user@example.com.sandbox'
export HUBOT_SFDC_PASSWORD='hogefuga'
export HUBOT_SFDC_LOGINURL='https://test.salesforce.com'
export HUBOT_SFDC_POLLING_INTERVAL=300000
```

#### Monitoring and Posting FeedComment Object
```bash
export HUBOT_SFDC_USERNAME='user@example.com'
export HUBOT_SFDC_PASSWORD='hogefuga'
export HUBOT_SFDC_QUERY_OBJECT='FeedComment'
```

#### Monitoring and Posting The Record/Group Feed
```bash
export HUBOT_SFDC_USERNAME='user@example.com'
export HUBOT_SFDC_PASSWORD='hogefuga'
export HUBOT_SFDC_PARENT_ID='001A0000019n4FhIAI' #Account Feed
 #export HUBOT_SFDC_PARENT_ID='0F9A0000000HZKUKA4' #Group Feed
```

## Contribute
Just send pull request if needed or fill an issue!

## License
The MIT License See [LICENSE](https://github.com/tzmfreedom/hubot-chatter/blob/master/LICENSE) file.