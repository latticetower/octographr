require 'json'
require 'redis'

require __dir__ + '/repo.rb'

class RedisStore

  REDIS_URL = ENV['HEROKU_REDIS_WHITE_URL']

  PREFIX_REPO = 'repo:'
  KEY_RECENT = "recent_repos"

  MAX_RECENT_REPOS = 10

  def initialize
    @redis = Redis.new :url => REDIS_URL
  end

  # Fetches repository info from Redis
  #
  # @param [String] full_name - owner/repo_name
  # @return [Repo]  - repository info
  def get_repo(full_name)
    repo = nil
    repo_json = @redis.get PREFIX_REPO + full_name
    if repo_json then
      repo = Repo.new
      repo.from_json!(repo_json)
    end
    repo
  end

  # Updates repository info in Redis
  #
  # @param [Repo] repo - repository info
  def put_repo(repo)
    full_name = repo.owner + '/' + repo.name
    names = @redis.lrange(KEY_RECENT, 0, MAX_RECENT_REPOS)
    @redis.multi do |tx|
      tx.set(PREFIX_REPO + full_name, repo.to_json)
      if !(names.include?(full_name))
        tx.lpush(KEY_RECENT, full_name)
        tx.ltrim(KEY_RECENT, 0, MAX_RECENT_REPOS - 1)
      end
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
