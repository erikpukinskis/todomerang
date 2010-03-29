require 'rubygems'
require 'sinatra'
require 'haml'
require 'dm-core'
require 'sinatra-authentication'
require 'json'
require 'chronic'
require 'active_support'

use Rack::Session::Cookie, :secret => ENV['SESSION_SECRET'] || 'This is a secret key that no one will guess~'

class Todo
  include DataMapper::Resource
  property :id, Serial
  property :note, String
  property :context_id, Integer
  property :time, DateTime
  attr_accessor :time_description
  belongs_to :dm_user
#  has 1, :context
  before :create, :parse_time

  def parse_time
    if time_description
      self.time = Chronic.parse(time_description)
    end
  end
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

  def days_with_todos
    todos.inject({}) do |days, todo|
      if todo.time
        key = todo.time.to_time.to_date_string
        days[key] ||= []
        days[key] << todo
      end
      days
    end.sort
  end
end

class Time
  def to_date_string
    strftime("%Y-%m-%d")
  end

  def fancy_date
    if to_date_string == Time.now.to_date_string
      "Today"
    elsif self < Date.today + 2.days
      "Tomorrow"
    elsif self < Date.today + 6.days
      strftime("%A")
    else
      strftime("%-1m/%-1d")
    end
  end
end

class Day
  attr_accessor :time, :user

  def initialize(user, string)
    self.time = Time.parse(string)
    self.user = user
  end

  def name
    time.fancy_date
  end

  def todos
    user.todos(:time.gt => time + 0.hours, :time.lt => time + 24.hours)
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")
DataMapper.auto_upgrade!

get '/' do
  if logged_in?
    @contexts = current_user.contexts
    @days = current_user.days_with_todos
  end
  haml :index
end

post '/contexts' do
  context = Context.create(params.merge({:dm_user_id => current_user.id}))
  context.attributes.to_json
end

post '/todos' do
  params["context_id"] = nil if params["context_id"] == 'nil'
  params["dm_user_id"] = current_user.id
  t = Todo.create(params)
  redirect '/'
end

get '/contexts/:id' do
  @context = Context.get(params[:id])
  @todos = @context.todos
  haml :context
end

get '/days/:id' do
  @context = Day.new(current_user, params[:id])
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

def fancy_date(date_string)
  time = Time.parse(date_string)
  time.fancy_date
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
    or time is
    %input{:name => 'time_description'}
    %input{:type => 'submit', :value => 'remember'}
  %h2 What's happening?  
  %ul#days.contexts
    - @contexts.each do |context|
      %li
        %a{:href => context.path}= context.name
  %h2 Future stuff
  %ul.contexts
    - @days.each do |date,todo|
      %li
        %a{:href => "/days/#{date}"}= fancy_date(date)
- else
  %p Sign up to post stuff!

@@ select_tag
%select{:name => name, :id => name}
  - objects.each do |object|
    %option{:value => object.send(value_param)}= object.send(label_param)
  %option{:value => 'nil', :selected => true} --
  %option{:onclick => "new_#{name}_option();"} New

@@ context
%h1= @context.name
%ul
- @todos.each do |todo|
  %li
    %input{:type => 'checkbox', :id => "todo_#{todo.id}"}
    %label{:for => "todo_#{todo.id}"}= todo.note
