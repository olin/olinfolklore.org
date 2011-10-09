div '#strip-files.system', ->
	h1 ->
	  text "Viewing attachments for "
	  a href: "/#{@data.strip.getId()}/", class: 'strip-id', -> "#{@data.strip.getId()}"
	  text ":"

	ul ->
		for file in @data.strip.files
			li ->
				a href: "#{file}", -> file
				form method: 'post', action: "#{file}", enctype: 'multipart/form-data', ->
					input type: 'file', name: 'file'
					br()
					input type: 'hidden', name: 'action', value: 'put'
					input type: 'submit', value: 'Update'
				form method: 'post', action: "#{file}", onsubmit: "return confirm('Are you sure you want to delete this file?')", ->
					input type: 'hidden', name: 'action', value: 'delete'
					input type: 'submit', value: 'Delete'

	form method: 'post', action: "?files", enctype: 'multipart/form-data', ->
		input type: 'file', name: 'file'
		input type: 'submit', value: 'Upload new file'