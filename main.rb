require 'rubygems'
require 'sinatra'
require 'haml'
require 'dm-core'
require 'sinatra-authentication'
require 'json'

use Rack::Session::Cookie, :secret => ENV['SESSION_SECRET'] || 'This is a secret key that no one will guess~'

class Todo
  include DataMapper::Resource
  property :id, Serial
  property :note, String
  property :context_id, Integer
  belongs_to :dm_user
  belongs_to :context
end

class Context
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  belongs_to :dm_user
  has n, :todos

  def path
    "/contexts/#{id}"
  end
end

class DmUser
  has n, :todos
  has n, :contexts
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")
DataMapper.auto_upgrade!

get '/' do
  if logged_in?
    @contexts = current_user.contexts
  end
  haml :index
end

post '/contexts' do
  context = Context.create(params.merge({:dm_user_id => current_user.id}))
  context.attributes.to_json
end

post '/todos' do
  Todo.create(params.merge({:dm_user_id => current_user.id}))
  redirect '/'
end

get '/contexts/:id' do
  @context = Context.get(params[:id])
  @todos = @context.todos
  haml :context
end

def name
  current_user.email.split("@")[0]
end

def select_tag(objects, name, value_param, label_param)
  haml :select_tag, :locals => {
    :objects => objects, 
    :name => name, 
    :value_param => value_param, 
    :label_param => label_param
  }, :layout => false
end

__END__

@@ layout
!!! XML
!!!
%html
  %head
    %title Todomerang!
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/base.css'}
    %script{:type => 'text/javascript', :src => '/form_helpers.js'}
    %script{:type => 'text/javascript', :src => '/mootools.js'}
  %body
    #top_bar
      %ul#account_links
        - if logged_in?
          %li Welcome #{name}!
          %li
            %a{:href => '/logout'} Log out
        - else
          %li
            %a{:href => '/login'} Log in
          %li
            %a{:href => '/signup'} Sign up
      #title
        %a{:href => '/'} Todomerang
    = yield
    #footer
      = 'Created by <a href="http://snowedin.net">Erik Pukinskis</a> (<a href="http://github.com/erikpukinskis/todomerang">source code</a>)'

@@ index
- if logged_in?
  %form{:method => 'post', :action => '/todos'}
    Remind me
    %input{:name => 'note'}
    when
    = select_tag(@contexts, 'context_id', :id, :name)
    %input{:type => 'submit', :value => 'remember'}
  %ul#contexts
    - @contexts.each do |context|
      %a{:href => context.path}= context.name
- else
  %p Sign up to post stuff!

@@ select_tag
%select{:name => name, :id => name}
  - objects.each do |object|
    %option{:value => object.send(value_param)}= object.send(label_param)
  %option --
  %option{:onclick => "new_#{name}_option();"} New

@@ context
%h1= @context.name
%ul
- @todos.each do |todo|
  %li
    %input{:type => 'checkbox', :id => "todo_#{todo.id}"}
    %label{:for => "todo_#{todo.id}"}= todo.note
