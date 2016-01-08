require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
	enable :sessions
	set :session_secret, 'secret'

end
helpers do
	def list_complete?(list)
		todos_count(list) > 0 && todos_remaining_count(list) == 0
	end

	def list_class(list)
		 "complete" if list_complete?(list)
	end

	def todos_count(list)
		list[:todos].size
	end

	def todos_remaining_count(list)
		list[:todos].select {|todo| !todo[:completed]}.size
	end
end
before do
	session[:lists] ||= []
end

get "/" do
	redirect "/lists"
end
#view all lists
get "/lists" do
	@lists = session[:lists]
  erb :lists, layout: :layout
end
#render a new list form
get "/lists/new" do
	erb :new_list, layout: :layout
end
#return error message if name is valid
def error_for_list_name(name)
	if !(1..100).cover? name.size 
		"List name must be between 1 and 100"
	elsif session[:lists].any? {|list| list[:name] == name }
		"list name must be unique!"
	end
end

def error_for_todo(name)
	if !(1..100).cover? name.size 
		"Todo must be between 1 and 100"
	end
end

def load_list(index)
	list = session[:lists][index] if index
	return list if list

	session[:error] = "the list you requested does not exist"
	redirect "/lists"
	halt
end

#create a new list
post "/lists" do
	list_name = params[:list_name].strip

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :new_list, layout: :layout
  else
  	session[:lists] << {name: list_name, todos: []}
	  session[:success] = "The list has been added successfully"
	  redirect "/lists"
  end
end

get "/lists/:id" do
	@list_id = params[:id].to_i
	@list = load_list(@list_id)
	erb :list, layout: :layout
end

get "/lists/:id/edit" do
	id = params[:id].to_i
	@list = load_list(id)
	erb :edit_list, layout: :layout
end

post "/lists/:id" do
	list_name = params[:list_name].strip
	id = params[:id].to_i
	@list = load_list(id)

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :edit_list, layout: :layout
  else
  	@list[:name] = list_name
	  session[:success] = "The list has been added update"
	  redirect "/lists/#{id}"
  end
end

post "/lists/:id/destroy" do
	id = params[:id].to_i
	session[:lists].delete_at(id)
	session[:success] = "The list has been deleted"
	redirect "/lists"
end

post "/lists/:list_id/todos" do
	@list_id = params[:list_id].to_i
	@list = load_list(@list_id)
	text = params[:todo].strip
	error = error_for_todo(text)
	if error
		session[:error] = error
		erb :list, layout: :layout
	else
	  @list[:todos] << {name: params[:todo], completed: false}
	  session[:success] = "todo List item successfully added"
	  redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id/destroy" do
	@list_id = params[:list_id].to_i
	@list = load_list(@list_id)
  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "todo List item successfully deleted"
	redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/todos/:id" do
	@list_id = params[:list_id].to_i
	@list = load_list(@list_id)

	todo_id = params[:id].to_i
	is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "todo is updated"
	redirect "/lists/#{@list_id}"
end

post "/lists/:id/completed_all" do
	@list_id = params[:id].to_i
	@list = load_list(@list_id)

	@list[:todos].each do |todo|
		todo[:completed] = true
	end
	session[:success] = "todo is completed"
	redirect "/lists/#{@list_id}"
end



