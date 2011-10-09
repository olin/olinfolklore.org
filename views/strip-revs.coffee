div '#strip-revs.system', ->
	h1 ->
		text "Revisions for " 
		a href: "/#{@data.strip.getId()}/", class: 'strip-id', -> @data.strip.getId()
		text ":"

	ul ->
		for rev in @data.revs
			li -> a href: "?rev=#{rev.id}",
				rev.time.format('{FullMonth} {Date}, {FullYear} @ {HoursMeridiem}:{Minutes:2} {Meridiem}')