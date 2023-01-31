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
  result = db.execute("SELECT * FROM RecensionId WHERE RecensionId = ?",id)
  slim(:"/review/index",locals:{recension:result})
end

get('/review/new') do
  slim(:"review/new")
end

post('/review/new') do
  id = session[:id].to_i
  review = params[:review]
  db = SQLite3::Database.new('db/imdb.db')
  db.execute("INSERT INTO recension (Content, RecensionId) VALUES(?,?)",review,id)
  redirect('/review')
end