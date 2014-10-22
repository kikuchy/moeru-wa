# Description:
#    Expanding Niconico Seiga Illust

jsdom = require "jsdom"
deferred = require "deferred"

module.exports = (robot) ->
    robot.hear /(http:\/\/lohas\.nicoseiga\.jp\/o\/[0-9a-f]+\/\d+\/\d+)/i, (msg) ->
        url = msg.match[1]
        parseNicoSeiIllustDataDef(url).then (illustData) ->
            msg.send illustData.imgUrl
        , (error) ->
            msg.send "モエナカッターワ…"
            console.error error

parseNicoSeiIllustDataDef = (url) ->
    ret = deferred()
    jsdom.env
        url: url
        done: (error, window) ->
            if error
                ret.reject error
            if window.location.href == url
                # not redirected
                img = window.document.querySelector ".illust_view_big img"
                title = window.document.title.split(" - ")[0]
                ret.resolve
                    imgUrl: img.src
                    title: title
                    url: url
            else
                # Redilected
                img = window.document.querySelector "#link_thumbnail_main img"
                title = window.document.querySelector ".lg_ttl_illust h1"
                caption = window.document.querySelector "meta[property$=description]"
                ret.resolve
                    imgUrl: img.src
                    title: title.innerHTML
                    url: url
                    caption: caption.content
            window.close()
    ret.promise
