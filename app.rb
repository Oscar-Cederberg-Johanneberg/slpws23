require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model.rb'

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
    id = result["UserId"]

    if BCrypt::Password.new(pwdigest) == password
      session[:user_id] = id
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
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/imdb.db')
    db.execute("INSERT INTO users (Username,pwdigest) VALUES (?,?)",username,password_digest)
    flash[:notice] = "Lyckad Registrering"
    redirect('/showlogin')
  else
    flash[:notice] = "Lösenorden var inte samma, skriv igen"
    redirect('/register')
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
  if session[:user_id]
    db = SQLite3::Database.new('db/imdb.db')
    db.results_as_hash = true
    genres = db.execute("SELECT * FROM genres")
    slim(:"review/new", locals: {genres: genres})
  else
    flash[:notice] = "Du måste vara inloggad för att skapa en recension"
    redirect('/showlogin')
  end
end

post('/review/new') do
  user_id = session[:user_id].to_i
  review = params[:review]
  title = params[:title]
  rating = params[:rating]
  genres = params[:genres]

  if title.strip.empty? || review.strip.empty? || rating.nil? || rating.strip.empty?
    flash[:notice] = "Kontrollera så att alla fält är ifyllda!"
    redirect('/review/new')
  elsif genres.nil? || genres.empty?
    flash[:notice] = "Välj minst en genre!"
    redirect('/review/new')
  else
    db = SQLite3::Database.new('db/imdb.db')
    db.execute("INSERT INTO recension(Content, Title, Rating, UserId) VALUES(?,?,?,?)", review, title, rating, user_id)
    recension_id = db.last_insert_row_id

    genres.each do |genre_id|
      db.execute("INSERT INTO recension_genre_rel (RecensionId, GenreId) VALUES (?, ?)", recension_id, genre_id)
  
    end
    flash[:notice] = "Recension Publicerad"
    redirect('/review')
  end
end

get('/recension/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/imdb.db')
  db.results_as_hash = true
  user = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  if session[:user_id] == user["UserId"] || session[:user_id] == 11
    result = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
    genres = db.execute("SELECT * FROM genres")
    selected_genres = db.execute("SELECT GenreId FROM recension_genre_rel WHERE RecensionId = ?", id).flatten
    slim(:"review/edit", locals: {result: result, genres: genres, selected_genres: selected_genres})
  else
    flash[:notice] = "Du kan endast redigera dina egna recensioner"
    redirect('/review')
  end
end

post('/recension/:id/update') do
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  id = params[:id].to_i
  title = params[:title]
  review = params[:review]
  rating = params[:rating]
  genres = params[:genres]
  user = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  if session[:user_id] == user["UserId"] || session[:user_id] == 11
    if title.strip.empty? || review.strip.empty? || rating.nil? || rating.strip.empty? || genres.nil? || genres.empty?
      flash[:notice] = "Alla fält måste fyllas i och minst en genre måste väljas."
      redirect back
    else
      db.execute("UPDATE recension SET Title=?, Content=?, Rating=? WHERE RecensionId =?",title,review,rating,id)
      redirect('/review')
    end
  else
    flash[:notice] = "Du kan endast redigera dina egna recensioner"
    redirect('/review')
  end
end

post('/recension/:id/delete') do
  review_id = params[:id].to_i
  user_id = session[:UserId].to_i
  db = SQLite3::Database.new('db/imdb.db')
  db.execute("DELETE FROM recension WHERE RecensionId = ?", review_id)
  flash[:notice] = "Recension raderad"
  redirect('/review')
end

get('/recension/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  user = db.execute("SELECT * FROM users WHERE UserId = ?", result["UserId"]).first
  genres = db.execute("SELECT g.* FROM genres g INNER JOIN recension_genre_rel rgr ON g.GenreId = rgr.GenreId WHERE rgr.RecensionId = ?", id)
  slim(:"review/show", locals: {result: result, user: user, genres: genres})
end
