require 'sidekiq'
require 'octokit'

require __dir__ + "/../downloader.rb"
require __dir__ + "/../redis_store.rb"

class DownloadWorker
  include Sidekiq::Worker
  def perform(full_name)
    redis_store = RedisStore.new
    repo = redis_store.get_repo(full_name)

    v = Octokit.archive_link(full_name)
    Downloader.new().start_download(v, repo.last_commit_sha)

    repo.state = 'done'
    redis_store.put_repo(repo)
  end
end
