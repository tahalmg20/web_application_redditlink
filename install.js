const bcrypt = require('bcrypt');
require('dotenv').config()
const host = process.env.DATABASE_HOST
const user = process.env.DATABASE_USER
const mdp = process.env.DATABASE_PASSWORD == undefined ? "" : process.env.DATABASE_PASSWORD;


function createDatabse(){

   const mysql = require('mysql');

   const connection = mysql.createConnection({
      host     : host,
      user     : user,
      password : mdp
   });


   connection.connect((err) => {
      if (err) throw err;  
      connection.query("CREATE DATABASE redditlink", function (err, result) {  
      if (err) throw err;  
      console.log("Database created");  
      });  
      return
   });
   return
}
function dropDatabase(){

   const mysql = require('mysql');

   const connection = mysql.createConnection({
      host     : host,
      user     : user,
      password : mdp
   });


   connection.connect((err) => {
      if (err) throw err;  
      connection.query("DROP SCHEMA IF EXISTS redditlink", function (err, result) {  
      if (err) throw err;  
      console.log("Database deleted");  
      });  
      return
   })
   return 
}
function connection(){
   
}
function dbconnect() {

   let mysql = require('mysql');
   

   let connection = mysql.createConnection({
      host     : host,
      user     : user,
      password : mdp,
      database : 'redditlink'
   });




   connection.connect((err) => {
      if (err) throw err;
      console.log("Connected!");

      var sql = "CREATE TABLE IF NOT EXISTS likes (id int(11) NOT NULL AUTO_INCREMENT,id_user int(11) NOT NULL,id_post int(11) NOT NULL, PRIMARY KEY (id))";
      connection.query(sql, function (err, result) {
         if (err) throw err;
         console.log("Table created");
      });

      sql = "CREATE TABLE IF NOT EXISTS post (id_posts int(11) NOT NULL AUTO_INCREMENT,id_writter int(11) NOT NULL,date_creation datetime NOT NULL DEFAULT current_timestamp(),link varchar(100) NOT NULL,content varchar(255) NOT NULL,PRIMARY KEY (id_posts))";
      connection.query(sql, function (err, result) {
         if (err) throw err;
         console.log("Table created");
      });

      sql = "CREATE TABLE IF NOT EXISTS users (id int(11) NOT NULL AUTO_INCREMENT,pseudo varchar(100) NOT NULL,email varchar(100) NOT NULL,mdp varchar(100) NOT NULL,PRIMARY KEY (id))";
      connection.query(sql, function (err, result) {
         if (err) throw err;
         console.log("Table created");
      });

   });
   return connection
}
async function createUser(connection){
   data = [
      'test@gmail.com',
      'UserTest',
      await bcrypt.hash('motdepasse', 10)
   ]
   connection.query('INSERT INTO users (email, pseudo, mdp) VALUES (?,?,?)', data, (err, user, field) => {

   });

}
function createPosts(connection){
   data = [
      'https://www.google.fr/',
      "Contrairement à une opinion répandue, le Lorem Ipsum n'est pas simplement du texte aléatoire. Il trouve ses racines dans une oeuvre de la littérature latine classique datant de 45 av. J.-C., le rendant vieux de 2000 ans. ",
      "1"
   ]
   connection.query('INSERT INTO post (link, content, id_writter) VALUES (?,?,?)', data, (err, user, field) => {

   });
}

function createLikes(connection){
   data = [
      1,
      1
   ]
   connection.query('INSERT INTO likes (id_post, id_user) VALUES (?,?)', data, (err, user, field) => {

   });
}

const getPost = async (connection) => {
   connection.query("SELECT * FROM post", function (err, result, fields) {
      if (err) throw err;
      return result
    });
}

const getNumberOfLiks = async (connection, idPost) => {
   connection.query("SELECT * FROM likes WHERE id_post = ?", [idPost], function (err, result, fields) {
      if (err) throw err;
      return result.length
   });
}



(async function(){
   dropDatabase();
   let connection = dbconnect();
   exports.db = connection;
   exports.getPost = getPost;
   exports.getLikes = getNumberOfLiks;
   await createDatabse();
   await createUser(connection);
   await createPosts(connection);
   await createLikes(connection);
   console.log('<==================>')
   console.log('Redditlink is ready')
}());
