require 'json'
require 'redis'

require __dir__ + '/repo.rb'

class RedisStore

  REDIS_HOST = "pub-redis-14629.us-east-1-4.5.ec2.garantiadata.com"
  REDIS_PORT = "14629"
  REDIS_PASS = "octographr"

  PREFIX_REPO = 'repo:'
  KEY_RECENT = "recent_repos"

  MAX_RECENT_REPOS = 10

  def initialize
    @redis = Redis.new \
      :host => REDIS_HOST,
      :port => REDIS_PORT,
      :password => REDIS_PASS
  end

  # Fetches repository info from Redis
  #
  # @param [String] full_name - owner/repo_name
  # @return [Repo]  - repository info
  def get_repo(full_name)
    repo = Repo.new
    repo.from_json!(@redis.get PREFIX_REPO + full_name)
    repo
  end

  # Updates repository info in Redis
  #
  # @param [Repo] repo - repository info
  def put_repo(repo)
    full_name = repo.owner + '/' + repo.name

    @redis.multi do |tx|
      tx.set(PREFIX_REPO + full_name, repo.to_json)
      tx.lpush(KEY_RECENT, full_name)
      tx.ltrim(KEY_RECENT, 0, MAX_RECENT_REPOS - 1)
    end
  end

  # Fetches recent repositories info
  #
  # @return [Array<Repo>]
  def get_recent_repos()
    repos = []
    names = @redis.lrange(KEY_RECENT, 0, MAX_RECENT_REPOS)

    names.each do |name|
      repo = get_repo(name)
      repos << repo
    end
    repos
  end
end
