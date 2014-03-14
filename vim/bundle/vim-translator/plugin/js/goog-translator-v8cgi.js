/*
 * @module goog-translator-v8cgi.js
 * @author maksimr
 * @driver v8cgi
 *
 * :v8cgi goog-translator-v8cgi.js "hello world" "en|ru"
 */

(function (sys) {
	"use strict";
	/*
   * include http module
   */
	require('http');

	/*
   * define used variables
   */
	var console = sys.stdout,
	query = sys.args[1],
  langpair = sys.args[2].split("|"),
	hl = langpair[0],
	tl = langpair[1],
	sl = hl,
	url = "translate.google.com/translate_a/t?client=t&text=" + query + "&hl=" + hl + "&sl=" + sl + "&tl=" + tl + "&multires=1&otf=1&ssel=0&tsel=0&sc=1",
	request = new ClientRequest(url),
	response,
	data;

	/*
  * trick for fix encoding
  */
	request.header({
		'user-agent': 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1'
	});
	/*
   * send request and get response
   */
	response = request.send();

	if (response.status === 200) {
    /*
     * data is Buffer object
     */
    data = eval(response.data);
    /*
     * convert Buffer to Array
     */
    data = eval(data.toString("utf-8",0,data.length));
    data = data[0][0][0];
	}

	console(data || "Sorry something went wrong");

} (system));
