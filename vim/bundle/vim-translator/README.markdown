translator.vim
============

* [This is a mirror of vim.org](http://www.vim.org/scripts/script.php?script_id=3404)

This script allows you to translate text using the google online translator.
You can translate as single words and whole blocks using visual-mode.

Use `:Translate Hello World` to translate words or sentences
Note: With a large number of text program can take some time

Installation
------------

For version 1.3 you may choose driver for translate, now available ruby ,node.js, v8cgi, lua

* Ruby
  * install ruby
  * install vim with supporting ruby

* Node.js
  * install node.js

* V8cgi
  * install v8cgi
  * [Documentation](http://code.google.com/p/v8cgi/wiki/Compiling)

* Lua
  * install lua
  * install vim with supporting lua
  * install socket.http for lua (liblua5.1-socket-dev for ubuntu)

If you use version 1.2(that do not support nodejs) you must install ruby and install gem json.

place files in `plugin` directory or under bundle `bundle/vim-translator`

Configuration
-------------

The whole setting is made through a variable `g:goog_user_conf` in your vimrc file.

---------

user configuration for ruby

```vim
  ".vimrc
  g:goog_user_conf = {
    'langpair': 'en|ru', "language code iso 639-1
    'v_key': 'T' "? define key in visual-mode (optional)
  }
```

user configuration for node.js


```vim
  ".vimrc
  g:goog_user_conf = {
    'langpair': 'en|ru', "language code iso 639-1
    'cmd': 'node',
    'v_key': 'T' "? define key in visual-mode (optional)
  }
```
user configuration for lua


```vim
  ".vimrc
  g:goog_user_conf = {
    'langpair': 'en|ru', "language code iso 639-1
    'cmd': 'lua',
    'v_key': 'T' "? define key in visual-mode (optional)
  }
```

user configuration with available parameters

```vim
  ".vimrc
  g:goog_user_conf = {
    'langpair': 'en|ru', "language code iso 639-1
    'cmd' : 'node',
    'v_key': 'T', "? define key in visual-mode (optional)
    'charset' : 'koi8-r' "? if need change encoding (use iconv) (optional)
  }
```
user configuration for v8cgi


```vim
  ".vimrc
  g:goog_user_conf = {
    'langpair': 'en|ru',
    'cmd': 'v8cgi'
  }
```

(version: 1.3.2)
