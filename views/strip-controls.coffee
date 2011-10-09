exports.run = ->
  div id: 'strip-tools', ->
    div id: 'strip-tools-edit', ->
      a href: '?edit', title: 'Edit this page', ->
        img src: 'https://s3.amazonaws.com/edit.io/static/icons/pencil.png'
        text ' Edit Page'
    
    form id: 'strip-tools-delete', method: 'post', onsubmit: "return confirm('Are you sure you want to delete this strip?')", ->
      input type: 'hidden', name: 'action', value: 'delete'
      button type: 'submit', id: 'strip-tools-delete-button', title: 'Delete this page', ->
        img src: 'https://s3.amazonaws.com/edit.io/static/icons/cross.png'
        text ' Delete Page'

    div id: 'strip-tools-share', ->
      a href: '?share', title: 'Share this page', ->
        img src: 'https://s3.amazonaws.com/edit.io/static/icons/group.png'
        text ' Share Page'

#if @prevCommit
#  a href: "?commit=#{@prevCommit}", 'Previous Revision'
#  text ' '
#if @nextCommit
#  a href: "?commit=#{@nextCommit}", 'Next Revision'