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

rightFill = (symbol, len, str) ->
    symbols = ''
    if str.length >= len
        return str
    for i in [1..(len - str.length)]
        symbols += symbol
    "#{str}#{symbols}"

# TODO: make part of plugin's configuration
LIMIT = 3

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
      body = []
      res.on "data", (chunk) ->
        body.push chunk
      .on "end", () ->

       result = eval body.join ''
       if decodeURIComponent(query).split(' ').length == 1
           [header, translates, misc] = result
           for translate in translates
               [entity, variants, details] = translate.slice(0, 3)

               console.log entity
               for variant, variantIx in variants
                   if variantIx == LIMIT
                       break
                   [word, trWords] = details[variantIx].slice(0, 2)
                   trWords = trWords.join ', '
                   console.log " -  #{rightFill(' ', 25, word + ":")}#{trWords}"
       else
           header = result[0]
           console.log header[0][0]


    .on 'error', (e) -> console.log "Error #{e}"
}

goog.translator.translate query, langpair
