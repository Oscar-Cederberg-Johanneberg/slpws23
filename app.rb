require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

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
  redirect('/review')
end

get('/recension/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/imdb.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM recension WHERE RecensionId = ?",id).first
  # result2 = db.execute("SELECT Title FROM recesion WHERE RecensionId IN (SELECT SongId FROM  WHERE AlbumId = ?)",id).first
  p "resultatet blev #{result2}"
  slim(:"review/show",locals:{result:result,result2:result2})
end