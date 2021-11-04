source 'https://rubygems.org'

ruby '3.0.2'

gem 'erubis'
gem 'sinatra', '~>1.4.7'
gem 'sinatra-contrib'

# to run the app at local enviroment (local machine), first run bundle config set --local without production
group :development do
  gem 'webrick'
end

# to run the app at production environment (heroku), delete the bundle folder and bundle install again
group :production do
  gem 'puma'
end
