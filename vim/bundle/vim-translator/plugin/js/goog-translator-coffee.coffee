#AUTHOR:  Maksim Ryzhikov
#NAME:    goog-translator-coffee.coffee
#DRIVER: nodejs
#VERSION: 0.1.0
#URL: https://github.com/maksimr

"use strict"

http = require "http"
query = process.argv[2]
langpair = process.argv[3]
goog = {}

goog.translator = {
  langpair: "en|ru"
  translate: (query,langpair) ->
    query = encodeURIComponent query
    [hl, tl] = langpair.split "|"
    sl = hl
    _outp = ''

    #send require
    http.get {
      host: 'translate.google.com',
      path: "/translate_a/t?client=t&text=#{query}&hl=#{hl}&sl=#{sl}&tl=#{tl}&multires=1&otf=1&ssel=0&tsel=0&sc=1",
      port: 80,
      headers: {
        #hack for fix encoding
        'user-agent': 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1'
      }
    }, (res) ->
      #handle response
      res.on "data", (chunk) ->
        jschunk = eval "(#{chunk})"
        _outp += jschunk[0][0][0]
      .on "end", () -> console.log _outp
    .on 'error', (e) -> console.log "Error #{e}"
}

goog.translator.translate query, langpair
