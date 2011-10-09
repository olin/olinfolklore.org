doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title "#{@title} | #{@req.user.id}.edit.io" if @title?
    meta(name: 'description', content: @description) if @description?

    meta name: 'viewport', content: 'width=device-width'
    meta name: 'viewport', content: 'initial-scale=1.0, user-scalable=no'

    link rel: 'icon', href: '/static.files/favicon.ico'

    script src: "https://s3.amazonaws.com/edit.io/static/showdown.js"
    script src: "https://s3.amazonaws.com/edit.io/static/mercutio.js"
    script src: "https://s3.amazonaws.com/edit.io/static/editor.js"

    noscript ->
      link rel: 'stylesheet', href: 'https://s3.amazonaws.com/edit.io/static/simple.css'
    script '''
var dynamic = true
if (dynamic) {
  document.write('<link rel="stylesheet" href="https://s3.amazonaws.com/edit.io/static/dynamic.css">')
  document.write('<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"></sc'+'ript>')
  document.write('<script src="https://s3.amazonaws.com/edit.io/static/dynamic.js"></sc'+'ript>')
} else {
  document.write('<link rel="stylesheet" href="https://s3.amazonaws.com/edit.io/static/simple.css">')
}
'''
    
  body class: @class, ->
    script '''
if (dynamic && document.body.className == 'strip')
  document.body.className += ' loading'
'''

    div id: 'header', ->
      div id: 'header-wrap', ->
        div id: 'logo', -> a href: '/', title: 'Home Page', -> "#{@req.user.id}.edit.io"

        form method: 'get', action: '/', id: 'strip-search', ->
          input type: 'hidden', name: 'list'
          button type: 'submit', id: 'strip-search-button', -> 'Search / See All Pages'
        
        rando = ('qwertyuiopasdfghjklzxcvbnm1234567890'.substr(Math.floor(Math.random()*36),1) for i in [0...8]).join('')
        form method: 'get', action: "/#{rando}/", id: 'newstrip', ->
          button type: 'submit', id: "newstrip-button", -> 'New Page'

        #a id: 'git-button', class: 'button', href: "/repo.git", -> 'Git Repo' 

        div id: 'user-status', ->
          if @req.user
            form method: 'post', action: '/?logout', ->
              text("Logged in as #{@req.user.id}. ")
              button type: 'submit', 'Logout?'
          else
            a href: '/?login', "Log in?"
        
      if controls? 
        div id: 'header-controls', ->
          div id: 'header-controls-wrap', ->
            controls()

    div id: 'the-fold', ->
      div id: 'body', ->
        div id: 'content', -> @body

        div id: 'footer', ->
          p -> 'edit.io &copy; 2011. All rights reserved.'

    script '''
if (dynamic && document.body.className.match(/\\bloading\\b/)) {
  document.body.className = document.body.className.replace(/\\bloading\\b/, '')
  window.scrollTo(0, document.getElementById("header").offsetHeight)
}
'''