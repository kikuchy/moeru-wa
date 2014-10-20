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
  robot.hear /(http:\/\/www\.pixiv\.net\/member_illust\.php\?.*&?(mode=medium&illust_id=\d+|illust_id=\d+&mode=medium))/i, (msg) ->
    url = extractSingleUrl(msg.match[1])
    parsePixivIllustDataDef(url).then((illustData) ->
      dlStream = downloadPixivImage(illustData)
      if process.env.HUBOT_SLACK_API_TOKEN
        console.log msg.room
        postImageToSlack(illustData, dlStream)
      msg.send "モエルーワ！"
    , (error) ->
      msg.send "モエナカッターワ…"
      console.error("作品の詳細情報の取得に失敗しました")
      console.error(error)
    )

# 文字列中に初めて出現するURLを取り出して返します
#
# @param [String] text 任意の文字列
#
extractSingleUrl = (text) ->
  text.match(/(https?|ftp)(:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/)[0]


# pixivのイラストページURLから、そのイラストの情報を取り出して返します
#
# @param [String] url pixivのイラスト詳細ページのURL
# @return [Object] ページURL, 画像サムネイルURL、イラストタイトル、イラストキャプションを含みます
#
parsePixivIllustDataDef = (url) ->
  ret = deferred()
  jsdom.env({
    url: url,
    done: (errors, window) ->
      if (errors)
        ret.reject(errors)
      img = window.document.querySelector(".img-container img")
      h1 = window.document.querySelector(".userdata h1.title")
      cap = window.document.querySelector("meta[property$=description]")
      if (!img || !h1 || !cap)
        ret.reject("DOMの取得に失敗。HTMLが変更されていないか確認")
      illustData = {
          url: url,
          title: h1.innerHTML,
          imgUrl: img.src,
          caption: cap.content
      }
      ret.resolve(illustData)
      window.close()
  })
  ret.promise

# イラスト画像のダウンロードを開始します
#
# @param [Object] pixivのイラスト情報
# @return [ReadableStream] 画像のStream
downloadPixivImage = (illustData) ->
  opt = {
    url: illustData.imgUrl
    headers: {
      Referer: illustData.url
    }
  }
  request(opt)


# Slackに画像を投稿します
#
# @param [Object] illustData イラストの情報
# @param [ReadableStream] dlStream 画像のStream
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
    if (error)
      console.error("Slackへのファイルのアップロードに失敗")
      console.error(err)
      return
    console.log("Slackへのファイルアップロードに成功")
    console.log(illustData)
  )
