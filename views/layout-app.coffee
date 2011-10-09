doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title "#{@title} | edit.io" if @title?
    meta(name: 'description', content: @description) if @description?

    meta name: 'viewport', content: 'width=device-width'
    meta name: 'viewport', content: 'initial-scale=1.0, user-scalable=no'

    link rel: 'icon', href: '/static.files/favicon.ico'
    link rel: 'stylesheet', href: '/static.files/screen.css'

    script src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js'
    script src: '/static.files/jquery-cookie.js'
    script src: '/static.files/code.js'
    
  body class: @class, ->
    div id: 'header', ->
      a href: '/', id: 'title', title: 'Home Page', -> 'edit.io'

    div id: 'content', -> @body

#    div id: 'footer', ->
#      p -> 'Copying &copy; 2011 Tim Cameron Ryan'