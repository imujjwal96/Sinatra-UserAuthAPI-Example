require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sinatra/namespace'
require 'json'

# adapted from http://datamapper.org/getting-started.html
# DataMapper.setup(:default, 'mysql://user:password@hostname/database')
DataMapper.setup(:default, 'mysql://root:@localhost/database_name')

# User Model
class User
  include DataMapper::Resource

  property :id,         	Serial
  property :username,   	String
  property :email,			String
  property :password,   	BCryptHash
  property :first_name, 	String
  property :last_name,  	String
  property :date_of_birth, 	String
  property :created_at,    	DateTime
end

DataMapper.auto_upgrade!

helpers do
  def valid_email? (email)
    regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    if email =~ regex
      return true
    end
    return false
  end
end

namespace '/api/v1/user' do
  before do
    content_type 'application/json'
  end

  post '/register/' do
    first_name      = params[:first_name].nil?      ? '' : params[:first_name] 
    last_name       = params[:last_name].nil?       ? '' : params[:last_name]
    username        = params[:username].nil?        ? '' : params[:username]
    email           = params[:email].nil?           ? '' : params[:email]
    password        = params[:password].nil?        ? '' : params[:password]
    password_repeat = params[:password_repeat].nil? ? '' : params[:password_repeat]
        
    if first_name.empty? or last_name.empty? or username.empty? or email.empty? or password.empty? or password_repeat.empty?
      halt 400, { message: "Empty Credentials." }.to_json
    end
    
    if !valid_email?(email)
      halt 400, { message: "Invalid Email id" }.to_json
    end

    if password != password_repeat
      halt 400, { message: "Passwords do not match." }.to_json
    end
    if User.count(:conditions => ['username = ?', username]) != 0
      halt 400, { message: "User with given username already exists." }.to_json
    end

    if User.count(:conditions => ['email = ?', email]) != 0
      halt 400, { message: "User with given email id already exists" }.to_json
    end 

    user = User.create(:username => username, :email => email, :password => password, :first_name => first_name, :last_name => last_name)
    if !user.saved?
      halt 400, { message: "Failed to register user." }.to_json
    end
    halt 200, { message: "User registered successfully." }.to_json
  end

  post '/login' do
    username = params[:username].nil? ? '' : params[:username]
    password = params[:password].nil? ? '' : params[:password]

    if username.empty?
      halt 400, { message: "Empty username." }.to_json
    end
    
    if password.empty?
      halt 400, { message: "Empty password." }.to_json
    end

    user = User.first(:username => username)
    if user.nil?
      halt 400, { message: "User does not exist." }.to_json
    end

    if user.password != password
      halt 400, { message: "Incorrect password." }.to_json
    end

    halt 200, { message: "Login successful." }.to_json
  end
end