div '#strip-missing.system', ->
	h1 ->
		text "The page "
		a class: 'strip-id', -> "\##{@id}"
		text " doesn't exist."

	form method: 'post', action: '/', ->
	  input type: 'hidden', name: 'id', value: "#{@id}"
	  button type: 'submit', -> 'Create this page'