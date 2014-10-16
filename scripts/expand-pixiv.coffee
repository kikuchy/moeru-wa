# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:
#   hubot ping - Reply with pong
#   hubot echo <text> - Reply back with <text>
#   hubot time - Reply with current time
#   hubot die - End hubot process

deferred = require('deferred')
jsdom = require("jsdom")
request = require("request")
fs = require("fs")

module.exports = (robot) ->
  robot.hear /(http:\/\/www\.pixiv\.net\/member_illust\.php\?mode=medium&illust_id=\d+)/i, (msg) ->
    url = extractSingleUrl(msg.match[1])
    parsePixivIllustDataDef(url).then((illustData) ->
      dlStream = downloadPixivImage(illustData)
      postImageToSlack(illustData, dlStream)
      msg.send "モエルーワ！"
    , (error) ->
      msg.send "モエナカッターワ…"
      console.error("作品の詳細情報の取得に失敗しました")
      console.error(error)
    )

extractSingleUrl = (text) ->
  text.match(/(https?|ftp)(:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/)[0]

parsePixivIllustDataDef = (url) ->
  ret = deferred()
  jsdom.env({
    url: url,
    done: (errors, window) ->
      if (errors)
        ret.reject(errors)
      img = window.document.querySelector(".img-container img")
      h1 = window.document.querySelector(".userdata h1.title")
      cap = window.document.querySelector("div.caption")
      if (!img || !h1 || !cap)
        ret.reject("DOMの取得に失敗。HTMLが変更されていないか確認")
      illustData = {
          url: url,
          title: h1.innerHTML,
          imgUrl: img.src,
          caption: cap.innerHTML
      }
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
  request(opt)

postImageToSlack = (illustData, dlStream) ->
  request.post({
    url: "https://slack.com/api/files.upload",
    formData: {
      token: process.env.HUBOT_SLACK_API_TOKEN,
      channels: "C02NK0E50",
      initial_comment: illustData.caption,
      title: illustData.title,
      file: dlStream
    }
  }, (err, resp, body) ->
    console.error("Slackへのファイルのアップロードに失敗")
    console.error(err)
  )
