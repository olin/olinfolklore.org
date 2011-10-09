div id: 'strip', ->
  h1 class: 'strip-title', ->
    text @data.rev.title or 'Untitled Page'
    text '&nbsp;'
    abbr class: 'strip-subtle-id', -> "\##{@data.strip.getId()}"

  div id: 'strip-stats', ->
      a href: '?history', title: 'See earlier revisions', id: 'strip-stats-history', ->
        img src: 'https://s3.amazonaws.com/edit.io/static/icons/time.png'
        text " Last edited #{@data.rev.time.format('{FullMonth} {Date}, {FullYear} @ {HoursMeridiem}:{Minutes:2} {Meridiem}')}"
      text ' '
      a href: '?files', title: 'View attached files', id: 'strip-stats-files', ->
        img src: 'https://s3.amazonaws.com/edit.io/static/icons/attach.png'
        text " #{@data.strip.files.length} attachment" + if @data.strip.files.length == 1 then '' else 's'

  text @data.html

#if @prevCommit
#  a href: "?commit=#{@prevCommit}", 'Previous Revision'
#  text ' '
#if @nextCommit
#  a href: "?commit=#{@nextCommit}", 'Next Revision'