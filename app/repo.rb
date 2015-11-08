require File.dirname(__FILE__) + '/jsonable.rb'

class Repo < JSONable
	attr_accessor :id
	attr_accessor :owner
	attr_accessor :name
	attr_accessor :url
	attr_accessor :last_commit
	attr_accessor :update_ts

	def initialize
	end

	def initialize(options = {})
		@id = options[:id]
		@owner = options[:owner]
		@name = options[:name]
		@url = options[:url]
		@last_commit = options[:last_commit]
		@update_ts = options[:update_ts]
	end
end

#{"@id": 24976407,"@owner": "nofate","@repo": "slang","@url": "https://github.com/nofate/slang","@last_commit": "54e7191d6ad8c09e31a5198405eb819e57683f03"}
