h1 "Log in to wiki \"#{@req.macheid}\""

form method: 'post', action: "/?login&redirect=#{@redirect}", ->
  #label -> text('Username:'); input name: 'username', maxlength: 256
  #br()
  label -> text('Password:'); input name: 'password', type: 'password', maxlength: 256
  br()
  button type: 'submit', 'Submit'

###
h1 'Register'

form method: 'post', action: '/?register', ->
  label -> text('Username:'); input name: 'username', maxlength: 256
  br()
  label -> text('Password:'); input name: 'password', type: 'password', maxlength: 256
  br()
  label -> text('Password again:'); input name: 'password2', type: 'password', maxlength: 256
  br()
  button type: 'submit', 'Submit'
###