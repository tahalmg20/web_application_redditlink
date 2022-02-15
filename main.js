const express = require('express');
const app = express();
const PORT = 3306;

const bodyParser = require('body-parser');
const path = require('path');
const bcrypt = require('bcrypt');
const session = require('express-session');


const con = require('./install');
const db = con.db;
const q = require('q');
const deferred = q.defer()

app.use(bodyParser.json()); // support json encoded bodies
app.use(express.urlencoded({ extended: false })); // support encoded bodies
app.use(express.static(path.join(__dirname, 'public')));
app.set('views', './views');
app.set('view engine', 'jade');

app.use(session({
	secret: 'secret',
	resave: true,
	saveUninitialized: true
}));



/* Routing */

// Get /////////////////////////////////////

// Accueil

function getLikes(id_post){
   db.query("SELECT COUNT(*) AS likesCount FROM likes WHERE id_post = ?", [id_post], (err, rows, fields) => {
      if (err) {      
         deferred.reject(err);
      }
      else {   
         deferred.resolve(rows[0].likesCount);     
      }    
   })

   return deferred.promise;
}

async function getPosts(result){
   r = []
   for await (const [key, value] of Object.entries(result)) {
      getLikes(value.id_posts).then(row => {
         r.append({
            'pseudo' : value.pseudo,
            'content' : value.content,
            'link' : value.link,
            'id_writter' : value.id_writter,
            'date_creation' : value.date_creation,
            'likes' : row
         })
      });
      deferred.resolve(r);  
   }  
   return r
}


app.get('/', async (req, res) => {

   let logged = req.session.loggedin == true ? true : false;
   if (req.session.loggedin) {
      await db.query(` SELECT date_creation, pseudo,id_posts, content, link, id_writter FROM post p INNER JOIN users u ON p.id_writter = u.id ORDER BY date_creation DESC`, async (err, result, fields) => {
         db.query('SELECT * FROM likes', (e,r,f) => {

            let posts = result;
            let likes = r;

            // Ajout du nombre likes

            for (let i=0;i<posts.length;i++){
               for (let j=0;j<likes.length;j++){
                  posts[i].likes = posts[i].likes !== undefined ? posts[i].likes : 0
                  if (likes[j].id_post == posts[i].id_posts){
                     posts[i].likes = posts[i].likes !== undefined ? posts[i].likes+=1 : 1
                  }
               }
            }



            res.render('home', {
               posts : posts,
               iduser : req.session.userid,
               likes: r,
               logged : logged,
               navactive : 1
            });

         })
      });
   } else {
      res.redirect('/login');
   }
   
});


app.get('/accueil', async (req, res) => {

   let logged = req.session.loggedin == true ? true : false;
   if (req.session.loggedin) {
      await db.query(` SELECT date_creation, pseudo,id_posts, content, link, id_writter FROM post p INNER JOIN users u ON p.id_writter = u.id ORDER BY date_creation DESC`, async (err, result, fields) => {
         db.query('SELECT * FROM likes', async (e,r,f) => {

            let posts = await result;
            let likes = await r;

            // Ajout du nombre likes

            for (let i=0;i<posts.length;i++){
               for (let j=0;j<likes.length;j++){
                  posts[i].likes = posts[i].likes !== undefined ? posts[i].likes : 0
                  if (likes[j].id_post == posts[i].id_posts){
                     posts[i].likes = posts[i].likes !== undefined ? posts[i].likes+=1 : 1
                  }
               }
            }



            res.render('home', {
               posts : posts,
               iduser : req.session.userid,
               likes: r,
               logged : logged,
               navactive : 1
            });

         })
      });
   } else {
      res.redirect('/login');
   }
   
});

// Pages

app.get('/tendances', async (req, res) => {
   let logged = req.session.loggedin == true ? true : false;
   if (req.session.loggedin) {
      await db.query(` SELECT date_creation, pseudo,id_posts, content, link, id_writter FROM post p INNER JOIN users u ON p.id_writter = u.id ORDER BY date_creation DESC`, async (err, result, fields) => {
         db.query('SELECT * FROM likes', (e,r,f) => {

            let posts = result;
            let likes = r;

            // Ajout du nombre likes

            for (let i=0;i<posts.length;i++){
               for (let j=0;j<likes.length;j++){
                  posts[i].likes = posts[i].likes !== undefined ? posts[i].likes : 0
                  if (likes[j].id_post == posts[i].id_posts){
                     posts[i].likes = posts[i].likes !== undefined ? posts[i].likes+=1 : 1
                  }
               }
            }

            // Tri par nombre de like décroissant 

            posts = posts.slice(0);
            posts.sort(function(a,b) {
                return a.likes - b.likes
            }).reverse();


            res.render('tendances', {
               posts : posts,
               iduser : req.session.userid,
               logged : logged,
               navactive : 2
            });

         })
      });
   } else {
      res.redirect('/login');
   }
});


// Espace connexion & inscription


app.get('/login', (req, res) => {
   res.render('login', {
      logged : false,
      navactive : 3
   })
});

app.get('/register', (req, res) => {
   res.render('register', {
      logged : false,
      navactive : 4
   })
});

// Compte

app.get('/mon-compte', async (req, res) => {
   let logged = req.session.loggedin == true ? true : false;
   if (req.session.loggedin) {
      let data = [
         req.session.userid
      ];
      await db.query('SELECT * FROM users WHERE id = ?', data, (err, user, field) => {
         res.render('user', {
            user : user[0],
            logged : logged
         })
      });
   } else {
      res.redirect('/login');
   }
});

app.get('/deconnexion', (req, res) => {
   req.session.loggedin = false;
   req.session.userid = 0;
   res.redirect('/login');
});

// Post /////////////////////////////////////

app.post('/home/:id', async (req, res) => {
   try {
      const params = req.body;
      if (params.desc.length > 1 && params.desc.length <= 255 && params.link.length > 1 && params.link.length < 100){
         data = [
            req.params.id,
            params.link,
            params.desc
         ]
         db.query('INSERT INTO post (id_writter, link, content) VALUES (?,?,?)', data, (err, user, field) => {
            res.redirect('/accueil');
         });
      }
   } catch {
      res.redirect('/accueil');
   }
});

app.post('/login', async (req, res) => {
   try {
      const params = req.body;
      if (params.mdp.length > 1 && params.email.length > 1){
         const mdp = params.mdp;
         data = [
            params.email
         ];
         db.query('SELECT * FROM users WHERE email = ?', data, async function(error, results, fields) {
            if (results.length > 0) {

               const comparison = await bcrypt.compare(mdp, results[0].mdp) 
               if(comparison){
                  req.session.loggedin = true;
                  req.session.userid = results.id;
                  res.redirect('/');
               }else{
                  res.send('Identifiants incorrects');
               }
            } else {
               res.send('Identifiants incorrects');
            }			
            res.end();
         });
      }
   } catch {
      res.redirect('/login');
   }
});

app.post('/register',  async (req, res) => {
   try {
      const params = req.body;
      if (params.mdp.length > 1 && params.mdpverif.length > 1 && params.email.length > 1 && params.pseudo.length > 1){
         if (params.mdp === params.mdpverif){
            data = [
               params.email,
               params.pseudo,
               await bcrypt.hash(params.mdp, 10)
            ]
            db.query('INSERT INTO users (email, pseudo, mdp) VALUES (?,?,?)', data, (err, user, field) => {
               if (err) {
                  res.redirect('/register')
               } else {
                  req.session.loggedin = true;
                  req.session.userid = user.insertId;
                  res.redirect('/accueil');
               }
            });
         }
      }
   } catch {
   }
});


app.post('/update/:id', async (req, res) => {
   try {
      const params = req.body;
      if (params.email.length > 1 && params.pseudo.length > 1 && params.mdp.length > 1 && params.mdpverif.length > 1){
         if (params.mdp == params.mdpverif){
            data = [
               params.email,
               params.pseudo,
               await bcrypt.hash(params.mdp, 10),
               req.params.id
            ]
            db.query('UPDATE users SET email = ?, pseudo = ?, mdp = ? WHERE id = ?', data, (err, user, field) => {
               res.redirect('/accueil'); 
            });
         }else{
            res.send('Les mots de passes ne correspondent pas');
         }
      }else{
         res.redirect('/accueil');
      }
   } catch {
      res.redirect('/accueil');
   }
});

app.post('/like/:post/:id', async (req, res) => {
   let data = [
      req.params.post,
      req.params.id
   ];
   db.query('SELECT * FROM likes WHERE id_post = ? AND id_user = ?', data, (err, result, fields) => {
      if (result.length <= 0){
         db.query('INSERT INTO likes (id_post, id_user) VALUES (?,?)', data, (e, r, f) => {
            res.redirect('/accueil');
         });
      }
   });
});

/*** Run ****/


app.listen(PORT,  () => {
   console.log(`Site en éxécution sur http://localhost:${PORT}`)
});

