(function() {
  "use strict";
  var goog, http, langpair, query;
  http = require("http");
  query = process.argv[2];
  langpair = process.argv[3];
  goog = {};
  goog.translator = {
    langpair: "en|ru",
    translate: function(query, langpair) {
      var hl, sl, tl, _outp, _ref;
      query = encodeURIComponent(query);
      _ref = langpair.split("|"), hl = _ref[0], tl = _ref[1];
      sl = hl;
      _outp = '';
      return http.get({
        host: 'translate.google.com',
        path: "/translate_a/t?client=t&text=" + query + "&hl=" + hl + "&sl=" + sl + "&tl=" + tl + "&multires=1&otf=1&ssel=0&tsel=0&sc=1",
        port: 80,
        headers: {
          'user-agent': 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1'
        }
      }, function(res) {
        return res.on("data", function(chunk) {
          var jschunk;
          jschunk = eval("(" + chunk + ")");
          return _outp += jschunk[0][0][0];
        }).on("end", function() {
          return console.log(_outp);
        });
      }).on('error', function(e) {
        return console.log("Error " + e);
      });
    }
  };
  goog.translator.translate(query, langpair);
}).call(this);
