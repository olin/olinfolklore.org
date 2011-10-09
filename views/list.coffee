div id: 'strip-list', class: 'system', ->
  h1 -> if @filter then "Viewing all pages:" else "Viewing pages matching \"#{@filter}\":"

  form method: 'get', action: '/', id: 'strip-list-search', ->
    input type: 'text', name: 'filter', id: 'strip-list-search-field', value: @req.query.filter
    input type: 'hidden', name: 'list'
    button type: 'submit', id: 'strip-list-search-button', -> 'Search'

  p class: 'list-data', -> 
    if not @strips?.length then "No strips found."
    else if @strips.length == 1 then "1 strip found:"
    else "#{@strips.length} strips found:"

  if @strips?.length
    ul class: 'list', ->
      for strip in @strips or []
        li ->
          h2 class: 'title', ->
            a href: strip.getId() + '/', ->
              text strip.title
              text ' '
              abbr class: 'strip-subtle-id', -> " \##{strip.getId()}"
          p class: 'date', -> "Edited #{strip.time?.format('{FullMonth} {Date}, {FullYear} @ {HoursMeridiem}:{Minutes:2} {Meridiem}')}"