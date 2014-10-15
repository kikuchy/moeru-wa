# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
#   hubot ping - Reply with pong
#   hubot echo <text> - Reply back with <text>
#   hubot time - Reply with current time
#   hubot die - End hubot process

domain = "alt-twitter"
token = "hoge"

deferred = require('deferred')
Slack = require("node-slack")
slackClient = new Slack(domain, token)
jsdom = require("jsdom")
request = require("request")
fs = require("fs")

module.exports = (robot) ->
  robot.respond /(http:\/\/www\.pixiv\.net\/member_illust\.php\?mode=medium&illust_id=\d+)/i, (msg) ->
    url = extractSingleUrl(msg.match[1])
    parsePixivIllustDataDef(url).then((illustData) ->
      tmpFilename = downloadPixivImage(illustData)
      postImageToSlack(illustData, tmpFilename)
      msg.send "モエルーワ！"
    )

extractSingleUrl = (text) ->
  text.match(/(https?|ftp)(:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/)[0]

parseIdFromPixivUrl = (url) ->
  params = url.split("?")[1].split("&")
  params.filter((p) ->
    p.indexOf("illust_id") > -1
  ).split("=")[1]

parseFilenameFromUrl = (url) ->
  idx = url.lastIndexOf("/")
  url.substring(idx + 1)

parsePixivIllustDataDef = (url) ->
  ret = deferred()
  jsdom.env({
    url: url,
    done: (errors, window) ->
      if (errors)
        ret.reject(errors)
      img = window.document.querySelector(".img-container img")
      h1 = window.document.querySelector(".userdata h1.title")
      cap = window.document.querySelector("#caption_long")
      illustData = {
          url: url,
          title: h1.innerHTML,
          imgUrl: img.src,
          caption: cap.innerHTML
      }
      console.log(illustData)
      ret.resolve(illustData)
      window.close()
  })
  ret.promise

downloadPixivImage = (illustData) ->
  opt = {
    url: illustData.imgUrl
    headers: {
      Referer: illustData.url
    }
  }
  filepath = "/tmp/" + parseFilenameFromUrl(illustData.imgUrl)
  request(opt).pipe(fs.createWriteStream(filepath))
  return filepath

postImageToSlack = (illustData, tmpFilename) ->
  request.post({
    url: "https://slack.com/api/files.upload",
    formData: {
      token: process.env.HUBOT_SLACK_TOKEN,
      channel: "C02NK0E50",
      initial_comment: illustData.caption,
      title: illustData.title,
      file: fs.createReadStream(tmpFilename)
    }
  })
