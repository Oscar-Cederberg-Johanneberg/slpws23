require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
# require 'bcrypt'
require 'sinatra/flash'

enable :sessions

get('/')  do
  slim(:start)
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
  id = session[:id].to_i
  review = params[:review]
  title = params[:title]
  rating = params[:rating]
  db = SQLite3::Database.new('db/imdb.db')
  db.execute("INSERT INTO recension(Content, Title, Rating) VALUES(?,?,?)",review, title, rating)
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
  db = SQLite3::Database.new("db/imdb.db")
  db.execute("DELETE FROM recension WHERE RecensionId =?",id)
  redirect('/review')
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