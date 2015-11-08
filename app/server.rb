require 'sinatra'
require 'slim'
require 'octokit'

require __dir__ + '/repo.rb'
require __dir__ + '/redis_store.rb'

OCTOKIT_CLIENT_ID = ENV['OCTOKIT_CLIENT_ID']
OCTOKIT_CLIENT_SECRET = ENV['OCTOKIT_CLIENT_SECRET']

use Rack::Session::Cookie, :secret => rand.to_s()

def authenticated?
  session[:access_token]
end

def authenticate!
  client = Octokit::Client.new
  url = client.authorize_url OCTOKIT_CLIENT_ID, :scope => 'user:email'

  redirect url
end

get '/' do
  @recent_repos = RedisStore.new().get_recent_repos()
  slim :index
end

get '/repo/:owner/:name' do
  owner = params['owner']
  name = params['name']
  @repo = RedisStore.new().get_repo(owner + '/' + name)

  slim :repo
end

post '/repo' do
  redirect to('/') if params['query'].nil?
  full_name = params['query'][/\A([\w-]+)\/([\w-]+)\z/]
  redirect to('/') if full_name.nil?

  owner, name = full_name.split("/")

  #todo: check in cache
  #todo: chech on github

  client = Octokit::Client.new \
    :client_id => OCTOKIT_CLIENT_ID,
    :client_secret => OCTOKIT_CLIENT_SECRET
  exists = client.repository? :repo => name, :owner => owner

  if !exists then
    redirect to('/')
  else
    result = client.repo :repo => name, :owner => owner
    branch = client.ref full_name, "heads/master"
    commit = client.commit full_name, branch.object.sha
    #TODO: use default branch instead of master

    repo = Repo.new \
      :id => result.id,
      :owner => result.owner.login,
      :name => result.name,
      :url => result.html_url,
      :last_commit_sha => branch.object.sha,
      :last_commit_url => commit.html_url,
      :update_ts => Time.now.to_i

    RedisStore.new().put_repo(repo)

    redirect to('/repo/' + owner + '/' + name)
  end
end

get '/draw_graph' do
  slim :test_graph, :layout => false
end

get '/login' do
  authenticate!
end

get '/auth_callback' do
  session_code = request.env['rack.request.query_hash']['code']
  result = Octokit.exchange_code_for_token(session_code, OCTOKIT_CLIENT_ID, OCTOKIT_CLIENT_SECRET)
  session[:access_token] = result[:access_token]
  
  client = Octokit::Client.new :access_token => access_token
  session[:user][:login] = client.user.login
  session[:user][:avatar_url] = client.user.avatar_url
  session[:user][:html_url] = client.user.html_url
  session[:user][:name] = client.user.name


  redirect '/'
end
