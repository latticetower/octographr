require 'sinatra'
require 'slim'
require 'octokit'

require __dir__ + '/repo.rb'
require __dir__ + '/redis_store.rb'
require __dir__ + '/workers/worker.rb'

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

def redirect_msg(path, message)
  logger.info 'Redirecting with message: ' + message
  session[:redirect_message] = message
  redirect path
end

get '/' do
  @recent_repos = RedisStore.new().get_recent_repos()
  slim :index
end

get '/repo/:owner/:name' do
  owner = params['owner']
  name = params['name']
  @repo = RedisStore.new().get_repo(owner + '/' + name)
  json_name = __dir__  + "/public/temp/#{@repo.last_commit_sha}.json"
  @data = {}

  @data = JSON.parse(File.read(json_name)) if File.exists?(json_name)

  slim :repo
end

post '/repo' do
  # validate input
  redirect_msg('/', 'Repository name expected') if params['query'].nil?

  full_name = params['query'][/\A([\w-]+)\/([\w-]+)\z/]
  redirect_msg('/', 'Bad repo name format.') if full_name.nil?

  owner, name = full_name.split("/")

  # Check in cache
  redis_store = RedisStore.new()
  repo = redis_store.get_repo(full_name)
  if repo then
    redirect to('/repo/' + full_name)
  end

  # Check on GitHub
  client = Octokit::Client.new \
    :client_id => OCTOKIT_CLIENT_ID,
    :client_secret => OCTOKIT_CLIENT_SECRET
  exists = client.repository? :repo => name, :owner => owner
  if !exists then
    redirect_msg('/', "Repository '#{full_name}' not found.")
  end

  # Check repo languages
  langs = client.languages full_name
  if not langs.to_hash.has_key? :Scala then
    redirect_msg('/', 'Sorry, only Scala repositories are currently supported.')
  end

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
    :update_ts => Time.now.to_i,
    :state => 'processing'
  redis_store.put_repo(repo)

  DownloadWorker.perform_async(full_name)

  redirect to('/repo/' + owner + '/' + name)
end

get '/draw_graph' do
  @data = JSON.parse(File.read(__dir__ + "/public/temp/test_repo.json"))
  slim :test_graph, :layout => false
end

get '/login' do
  authenticate!
end

get '/logout' do
  session[:access_token] = nil
  session[:user] = {}

  redirect '/'
end

get '/auth_callback' do
  session_code = request.env['rack.request.query_hash']['code']
  result = Octokit.exchange_code_for_token(session_code, OCTOKIT_CLIENT_ID, OCTOKIT_CLIENT_SECRET)
  session[:access_token] = result[:access_token]

  client = Octokit::Client.new :access_token => result[:access_token]
  session[:user] = {}
  session[:user][:login] = client.user.login
  session[:user][:avatar_url] = client.user.avatar_url
  session[:user][:html_url] = client.user.html_url
  session[:user][:name] = client.user.name


  redirect '/'
end

before do
  @redirect_message = session[:redirect_message]
  session[:redirect_message] = nil
end
