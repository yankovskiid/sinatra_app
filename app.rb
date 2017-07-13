require 'sinatra'
require 'sinatra/activerecord'
require './config/environments'
require 'json'
require 'dotenv'
require './models/model'
require 'slim'
require 'rest-client'
require 'pry'
require 'octokit'
require 'jwt'

Dotenv.load
$token
CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']

#enable :session
#set :session,:expires => (Time.now + 3600*24)
set :sessions, true

def current_user
  @current_user ||= session[:access_token] && Model.find_by(token: session[:access_token])
end

def create(user_info, token)
  if  !user = Model.find_by(name: user_info.login)
    user = Model.create!(name: user_info.login, email:user_info.user[:email], token: token)
  else
    user[:token] = token
    user.save!
  end
end


def generate_token(access_token)
  rsa_private = OpenSSL::PKey::RSA.generate 2048
  rsa_public = rsa_private.public_key
  token = JWT.encode access_token.to_s, rsa_private, 'RS256'
end

def decode_token(access_token)
  decoded_token = JWT.decode access_token, rsa_public
end

def get_user(token)
  client = Octokit::Client.new(:access_token => token)
end

get '/' do
  if current_user.nil?
    erb :login, :locals => {:client_id => CLIENT_ID}
  else
    erb :home, :locals =>{:user_list => Model.all.map{|el| el.name}} end end
get '/callback' do
  session_code = request.env['rack.request.query_hash']['code']
  result = RestClient.post('https://github.com/login/oauth/access_token',
                          {:client_id => CLIENT_ID,
                           :client_secret => CLIENT_SECRET,
                           :code => session_code},
                           :accept => :json)
  token = JSON.parse(result)['access_token']
  client = get_user(token)
  access_token = generate_token(token)
  session[:access_token] = access_token
  create(client, access_token)
  redirect '/'
end
