require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for' # allows us to store blocks of html in a template and render their content anywhere in the layout (see content_for and yield_content). To use it we need to include gem 'sinatra-contrib' in our project (in the Gemfile)
require 'tilt/erubis'

# this code allows Sinatra to keep track of sessions, to not to loose data every time we reaload Sinatra
configure do
  enable :sessions # this activates the Sinatra sessions support
  set :session_secret, 'secret' # this sets the session_secret; the name here is just random
  set :erb, :escape_html => true
end

helpers do # here we put methods that we want to have use in both, the application file and any template (methods non intended to be used in the templates, shouldn't be placed in here)
  def list_completed?(list) # this method returns a boolean according to the completion of all todos for list that aren't empty (like new empty lists)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list) # this method will determine which class to use in a tag in templates, according to the completion of all todos
    "complete" if list_completed?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| todo[:completed] == false }
  end
  # the following two methods, are used to organize the way the todos and the lists are displayed (according to their completion)
  # both, sort_lists and sort_todos do the same, but taking different approaches; I'll keep both versions to illustrate different ways of coding the same thing
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo[:completed] == true
        complete_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

before do
  session[:lists] ||= [] # if nothing is yet stored in session (if session[:lists] is falsey), we assign it to an empty array ('||= []' does that), so no error is generated when we start the app for first time
end

get '/' do
  redirect '/lists'
end

# View all todo lists
get '/lists' do
  @lists = session[:lists] # this code will try access the lists stored in session
  erb :lists
end

# Render the 'create new list' form
get '/lists/new' do
  erb :new_list
end

# Return error msg (string) if name is invalid; otherwise return nil
def error_for_list_name(name)
  if !(1..100).cover? name.size # making sure the entered name for new list is not empty string
    'The name of the list must be between 1 and 100 characters long.'
  elsif session[:lists].any? { |list| list[:name] == name } # making sure the entered name does not exist in the session hash
    'The name of the list must be unique.'
  end
end

# Return error msg (string) if name is invalid; otherwise return nil
def error_for_todo(name)
  if !(1..100).cover? name.size
    'The todo must be between 1 and 100 characters long.'
  end
end

# Create a new list
post '/lists' do # now we are dealing with a post route, coming from form input
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: params[:list_name], todos: [] } # the :list_name key of the params hash comes from the form, from the 'name' attribute in the 'input' tag
    session[:success] = 'Your new list has been created.' # this line here assigns a key-val to the session hash to indicate a new todo has been created so a flash msg can be printed
    redirect '/lists'
  end
end

# View an existing list
get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  erb :list
end

# Editing an existing list
get '/lists/:list_id/edit' do
  id = params[:list_id].to_i
  @list = session[:lists][id]
  erb :edit_list
end

# Update existing todo list
post '/lists/:list_id' do
  id = params[:list_id].to_i
  @list = session[:lists][id]
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name # updating the value of :name key in the todo hash in the lists array, element id
    session[:success] = 'The list name has been updated.'
    redirect "/lists/#{id}"
  end
end

# Delete todo list from lists array
post '/lists/:list_id/delete' do
  id = params[:list_id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Add todo item to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = 'Your new todo has been created.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete todo from todo list
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = 'The list has been deleted.'
  redirect "/lists/#{@list_id}"
end

# Update state of a todo (completed true or false)
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed

  session[:success] = 'The todo has been updated.'
  redirect "/lists/#{@list_id}"
end

# Mark all todos in a list as done
post '/lists/:list_id/all_done' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = 'All todos has been completed.'
  redirect "/lists/#{@list_id}"
end
