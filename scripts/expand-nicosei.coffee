# Description:
#    Expanding Niconico Seiga Illust

jsdom = require "jsdom"
deferred = require "deferred"

module.exports = (robot) ->
    robot.hear /(http:\/\/lohas\.nicoseiga\.jp\/o\/[0-9a-f]+\/\d+\/\d+)/i, (msg) ->
        pasteThumbnailUrlCallback generateThumbnailPageUrlFromOriginalSizePageUrl(msg.match[1]), msg
    robot.hear /(http:\/\/seiga\.nicovideo\.jp\/seiga\/im\d+)/i, (msg) ->
        pasteThumbnailUrlCallback msg.match[1], msg

pasteThumbnailUrlCallback = (url, msg) ->
    parseNicoSeiIllustDataDef(url, extractFromThumbnailPage).then (illustData) ->
        msg.send illustData.imgUrl
    , (error) ->
        msg.send "モエナカッターワ…"
        console.error error

parseNicoSeiIllustDataDef = (url, extractor) ->
    ret = deferred()
    jsdom.env
        url: url
        done: (error, window) ->
            if error
                ret.reject error
            else
                ret.resolve extractor(window)
            window.close()
    ret.promise

# いつかログイン機能が実装できたときのために残しておく
extractFromOriginalSizePage = (window) ->
    img = window.document.querySelector ".illust_view_big img"
    title = window.document.title.split(" - ")[0]
    imgUrl: img.src
    title: title
    url: window.location.href

extractFromThumbnailPage = (window) ->
    img = window.document.querySelector "#link_thumbnail_main img"
    title = window.document.querySelector ".lg_ttl_illust h1"
    caption = window.document.querySelector "meta[property$=description]"
    imgUrl: img.src
    title: title.innerHTML
    url: window.location.href
    caption: caption.content

generateThumbnailPageUrlFromOriginalSizePageUrl = (ou) ->
    illustId = ou.match(/http:\/\/lohas\.nicoseiga\.jp\/o\/[0-9a-f]+\/\d+\/(\d+)/)[1]
    "http://seiga.nicovideo.jp/seiga/im" + illustId

