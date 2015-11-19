require 'sidekiq'
require 'octokit'
require "base64"

require __dir__ + "/../downloader.rb"
require __dir__ + "/../redis_store.rb"

class DownloadWorker
  include Sidekiq::Worker
  def perform(full_name)
    redis_store = RedisStore.new
    repo = redis_store.get_repo(full_name)

    v = Octokit.archive_link(full_name)
    downloader = Downloader.new()
    archive_name = downloader.start_download(v, repo.last_commit_sha)
    v = downloader.get_hash(archive_name)

    json_file = __dir__ + "/../public/temp/#{repo.last_commit_sha}.json"
    result = downloader.collect_from_hash(v)
    downloader.save_to_json(json_file, result.to_json)

    repo.graph_data = Base64.encode64(result.to_json.to_s)
    downloader.remove_temp_archive(archive_name)

    repo.state = 'done'
    redis_store.put_repo(repo)
  end
end
