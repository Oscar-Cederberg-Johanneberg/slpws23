require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

get('/')  do
  slim(:start)
end

get('/reviews')

end

get('/reviews/new')
end