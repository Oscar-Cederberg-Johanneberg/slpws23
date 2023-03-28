require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'

enable :sessions

get('/')  do
  slim(:start)
end  

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/imdb.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  if result
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      flash[:notice] = "Inloggning Lyckades"
      redirect('/review')
    else
      flash[:notice] = "Användarnamnet är rätt, men det är fel lösenord"
      redirect('/showlogin')
    end
  else
    flash[:notice] = "Användarnamnet finns inte"
    redirect('/showlogin')
  end
end

get('/register') do
  slim(:register)
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    #skapa en ny användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/imdb.db')
    db.execute("INSERT INTO users (Username,pwdigest) VALUES (?,?)",username,password_digest)
    flash[:notice] = "Lyckad Registrering"
    redirect('/showlogin')
  else
    "Lösenorden var inte samma, skriv igen"
  end
end

get('/review') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/imdb.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension")
  slim(:"/review/index",locals:{recension:result})
end

get('/review/new') do
  slim(:"review/new")
end

post('/review/new') do
  user_id = session[:id].to_i
  review = params[:review]
  title = params[:title]
  rating = params[:rating]
  db = SQLite3::Database.new('db/imdb.db')
  db.execute("INSERT INTO recension(Content, Title, Rating, UserId) VALUES(?,?,?,?)", review, title, rating, user_id)
  flash[:notice] = "Recension Publicerad"
  redirect('/review')
end

get('/recension/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/imdb.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  slim(:"/review/edit",locals:{result:result})
end

post('/recension/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  review = params[:review]
  rating = params[:rating]
  db = SQLite3::Database.new("db/imdb.db")
  db.execute("UPDATE recension SET Title=?, Content=?, Rating=? WHERE RecensionId =?",title,review,rating,id)
  redirect('/review')
end

post('/recension/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id].to_i
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension WHERE RecensionId = ?", id).first

  if result["UserId"] == user_id
    db.execute("DELETE FROM recension WHERE RecensionId =?", id)
    flash[:notice] = "Recension Deleted"
    redirect('/review')
  else
    flash[:error] = "You do not have permission to delete this review"
    redirect("/recension/#{id}")
  end
end

get('/recension/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  # result2 = db.execute("SELECT Content FROM recension WHERE RecensionId IN (SELECT SongId FROM  WHERE AlbumId = ?)",id).first
  # p "resultatet blev #{result2}"
  slim(:"review/show",locals:{result:result})
end