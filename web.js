(function() {
  var Comment, MongoStore, Story, User, app, bcrypt, coffeekup, config, express, form, fs, markdown, mime, mongoose, parallel, path, port, querystring, serial, url, verifyEmail, _ref, _ref2;
  express = require('express');
  fs = require('fs');
  path = require('path');
  mime = require('mime');
  form = require('connect-form');
  bcrypt = require('bcrypt');
  querystring = require('querystring');
  _ref = require('pour'), serial = _ref[0], parallel = _ref[1];
  MongoStore = require('connect-mongo');
  mongoose = require('mongoose');
  markdown = require("markdown").markdown;
  coffeekup = require('coffeekup');
  url = require('url');
  _ref2 = require('./models'), User = _ref2.User, Comment = _ref2.Comment, Story = _ref2.Story;
  config = {
    MONGO_USER: 'heroku_app1398322',
    MONGO_PASS: 'a160eaj59k4m50hv5t7plnta9r',
    MONGO_HOST: 'dbh55.mongolab.com',
    MONGO_PORT: '27557',
    MONGO_DB: 'heroku_app1398322',
    secret: "panda-bears-dont-kill-for-free"
  };
  app = express.createServer(express.logger(), express.bodyParser(), form({
    keepExtensions: true
  }));
  app.use(express.cookieParser());
  app.use(express.static(__dirname + '/public'));
  app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));
  app.set('view engine', 'jade');
  mongoose.connect("mongodb://" + ("" + config.MONGO_USER + ":" + config.MONGO_PASS + "@") + ("" + config.MONGO_HOST + ":" + config.MONGO_PORT + "/" + config.MONGO_DB));
  app.use(express.session({
    secret: "animorphs",
    store: new MongoStore({
      host: config.MONGO_HOST,
      port: config.MONGO_PORT,
      db: config.MONGO_DB,
      username: config.MONGO_USER,
      password: config.MONGO_PASS
    })
  }));
  verifyEmail = function(audience, assertion, cb) {
    var data, opts, vreq;
    opts = {
      host: 'diresworb.org',
      path: "/verify",
      method: "POST"
    };
    vreq = require('https').request(opts, function(vres) {
      var body;
      body = "";
      return vres.on("data", function(chunk) {
        return body += chunk;
      }).on("end", function() {
        var email, valid, verifierResp;
        try {
          verifierResp = JSON.parse(body);
          valid = verifierResp && verifierResp.status === "okay";
          email = (valid ? verifierResp.email : null);
          if (valid) {
            console.log("assertion verified successfully for email:", email);
          } else {
            console.log("failed to verify assertion:", verifierResp.reason);
          }
          return cb(email);
        } catch (e) {
          console.log("non-JSON response from verifier", e);
          return cb(null);
        }
      });
    });
    vreq.setHeader("Content-Type", "application/x-www-form-urlencoded");
    data = querystring.stringify({
      assertion: assertion,
      audience: audience
    });
    vreq.setHeader("Content-Length", data.length);
    vreq.write(data);
    vreq.end();
    return console.log("verifying assertion!");
  };
  app.use(function(req, res, next) {
    var _ref3;
    path = url.parse(req.url, true);
    if ((_ref3 = path.pathname) === '/login' || _ref3 === '/logout') {
      next();
      return;
    }
    req.session.user = null;
    if (req.session.user) {
      return User.findById(req.session.user, function(err, user) {
        if (user) {
          req.user = user;
          return next();
        } else {
          return res.redirect('/login');
        }
      });
    } else {
      return res.redirect('/login');
    }
  });
  app.get('/', function(req, res) {
    return Story.find({}, function(err, stories) {
      return res.render('index', {
        req: req,
        stories: stories
      });
    });
  });
  app.get("/login", function(req, res) {
    return res.render('login', {
      req: req,
      layout: null
    });
  });
  app.post("/login", function(req, res) {
    var assertion, audience;
    audience = (req.headers["host"] ? req.headers["host"] : 'localhost');
    assertion = req.body.assertion;
    return verifyEmail(audience, assertion, function(email) {
      if (!email) {
        res.send({
          email: null,
          message: "Not able to verify email address."
        });
        return;
      }
      if (email === 'id@timryan.org') {
        email = "timothy.ryan@students.olin.edu";
      }
      if (!email.match(/@(students|alumni).olin.edu/)) {
        res.send({
          email: null,
          message: "Only valid @students.olin.edu or @alumni.olin.edu email addresses permitted."
        });
        return;
      }
      return User.findById(req.session.user, function(err, user) {
        if (!user) {
          user = new User();
          user._id = email;
          user.name = email.replace(/@.*$/, '');
          user.registered = new Date();
          user.save();
        }
        req.session.user = user._id;
        return res.send({
          email: email,
          message: "You are now logged in as " + email + "."
        });
      });
    });
  });
  app.post("/logout", function(req, res) {
    req.session.user = null;
    return res.redirect('/login');
  });
  app.get('/stories/', function(req, res) {
    return res.render('story-new', {
      req: req
    });
  });
  app.post('/stories/', function(req, res) {
    var story;
    story = new Story();
    story.user = req.user._id;
    story.time = new Date();
    story.occurred = req.body.date;
    story.title = req.body.title;
    story.tags = req.body.tags.split(/,\s+/);
    story.summary = req.body.summary;
    story.content = req.body.content;
    story.save();
    return res.redirect("/stories/" + story.id);
  });
  app.get('/stories/:id', function(req, res) {
    return Story.findById(req.params.id, function(err, story) {
      var comment, comments, _i, _len, _ref3;
      if (!story) {
        res.send("No story by that ID found.");
        return;
      }
      comments = [];
      _ref3 = story.comments;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        comment = _ref3[_i];
        comments.push({
          content: comment.content,
          time: comment.time,
          user: User.findOne({
            _id: comment.user
          })
        });
      }
      console.log(comments);
      return User.findById(story.user, function(err, author) {
        var html;
        html = markdown.toHTML(story.content);
        return res.render('story', {
          req: req,
          story: story,
          author: author,
          comments: comments,
          html: html
        });
      });
    });
  });
  app.post('/stories/:id', function(req, res) {
    return Story.findById(req.params.id, function(err, story) {
      var i;
      if (!story) {
        res.send("No story by that ID found.");
        return;
      }
      switch (req.body.action) {
        case 'favorite':
          story.favorites.push(req.user._id);
          console.log(story);
          story.save();
          break;
        case 'unfavorite':
          if ((i = story.favorites.indexOf(req.user._id)) !== -1) {
            story.favorites = story.favorites.splice(i, 1);
          }
          story.save();
          break;
        case 'comment':
          story.comments.push({
            user: req.user._id,
            content: req.body.comment,
            time: new Date()
          });
          story.save();
      }
      return res.redirect('/stories/' + req.params.id);
    });
  });
  port = process.env.PORT || 3000;
  app.listen(port);
  console.log("Listening on port " + port + "...");
}).call(this);
