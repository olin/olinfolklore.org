div '#strip-edit.system', ->
	h1 ->
		text "Editing "
		a href: "/#{@data.strip.getId()}/", class: 'strip-id', -> @data.strip.getId()
		text ":"

	form id: 'strip-edit-form', method: 'post', ->
	  div id: 'strip-edit-field', ->
	  	textarea rows: 25, cols: 50, name: 'content', -> @data.strip.content
	  input type: 'hidden', name: 'action', value: 'put'
	  input type: "submit", value: "Update Page"
	  text " "
	  a '.button', href: "?", -> "Cancel"