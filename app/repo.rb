require __dir__ + '/jsonable.rb'

class Repo < JSONable
  attr_accessor :id
  attr_accessor :owner
  attr_accessor :name
  attr_accessor :url
  attr_accessor :last_commit_sha
  attr_accessor :last_commit_url
  attr_accessor :update_ts
  attr_accessor :state  # processing or done
  attr_accessor :graph_data

  def initialize(options = {})
    @id = options[:id]
    @owner = options[:owner]
    @name = options[:name]
    @url = options[:url]
    @last_commit_sha = options[:last_commit_sha]
    @last_commit_url = options[:last_commit_url]
    @update_ts = options[:update_ts]
    @state = options[:state]
    @graph_data = options[:graph_data]
  end
end
