for (let i=0;i<posts.length;i++){
   for (let j=0;j<likes.length;j++){
      if (likes[j].id_post == posts[i].id_posts){
         posts[i].likes = posts[i].likes !== undefined ? posts[i].likes+=1 : 1
      }
   }
}

const all_posts = posts