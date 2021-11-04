source 'https://rubygems.org'

ruby '3.0.2'

gem 'erubis'
gem 'sinatra', '~>1.4.7'
gem 'sinatra-contrib'

# to run the app at local enviroment, first run bundle config set --local without production 
group :development do
  gem 'webrick'
end

group :production do
  gem 'puma'
end
