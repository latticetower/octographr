require 'http'
require 'rubygems/package'
require 'open-uri'
require 'open_uri_redirections'
require 'fileutils'

require __dir__ + "/scala_parser.rb"

class Downloader
  attr_reader :repo_path
  def initialize()
    #@repo_path = path
    @parser = ScalaParser.new
  end

  def start_download(path, target)
    g = open(__dir__ + "/public/temp/#{target}.log", 'w')
    begin
      g.write(path)
    ensure
      g.close()
    end
    archive_name = __dir__ + "/public/temp/#{target}.tar.gz"
    begin
      opened_url = open(path, "User-Agent" =>"octographr", :allow_redirections => :safe) #{|f|
      #f.each_line {|line| p line}
      #}
      #puts(opened_url.status)
      #puts(opened_url.read)
    rescue Timeout::Error
      puts "The request for a page at #{path} timed out...skipping."
      return
    rescue OpenURI::HTTPError => e
      puts "The request for a page at #{path} returned an error. #{e.message}"
      return
    end
    f = open(archive_name, 'wb')
    begin
      f.write(opened_url.read)

      #system("wget --user-agent='octographr' -P #{__dir__ }/public/temp #{repo_path}")
      #Curl::Easy.perform(@repo_path) do |curl|
      #  curl.headers["User-Agent"] = "octographr"
      #  curl.verbose = true
      #  curl.follow_location = true
      #  curl.on_body{|data| f.write(data); data.size  }
      #end
      #HTTP.headers("User-Agent" => "octographr").get(@repo_path).body do |resp|
      #  while !(part = resp.readpartial).nil? do
      #    f.write(part)
      #  end
      #end
    ensure
      f.close()
    end
    g = open(__dir__ + "/public/temp/#{target}.txt", 'w')
    begin
      g.write(get_hash(archive_name))
    ensure
      g.close()
    end
    archive_name
  end

  def remove_temp_archive(archive_name)
    FileUtils.rm(archive_name) if File.exists? archive_name
  end

  def get_hash(archive_name)
    get_sources_for_archive(archive_name) do |file_contents|
      @parser.parse_file(file_contents)
    end
  end

  def get_sources_for_archive(archive_name, file_types = [".scala"])
    result = []
    File.open(archive_name, "rb") do |file|
      Zlib::GzipReader.wrap(file) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each do |entry|
            result << yield(entry.read) if entry.file? and file_types.include? File.extname(entry.full_name)
          end
        end
      end
    end if block_given?
    result
  end

  def select_shape(x, classes, trait_names)
    if classes.include? x
      'rectangle'
    else
      'ellipse'
    end
  end

  def collect_from_hash(v)
    vv = v.flat_map{|x| x[:elements]}.compact
    trait_names = vv.map{|x| x[:trait_name]}.compact
    parent_types = vv.flat_map{|x| x[:parent]}.compact.map{|x| x[:parent_type]}
    constructor_types = vv.flat_map{|x| x[:params]}.compact.map{|x| x[:var_type][:type]}
    classes =  vv.flat_map{|x| x[:current_class]}.compact
    nodes = [classes, parent_types, trait_names, constructor_types].flatten.map(&:to_s).uniq.map{|x|
      {:data => {:id => x, :name => x, :weight => 25, :faveColor=> 'navy', :faveShape => select_shape(x, classes, trait_names)
        }}
    }

    edges = vv.select{|x|x[:current_class]}.select{|y| y[:parent]}.map{|x|
       [x[:parent]].flatten.map{|y|
      {:data => {:source => x[:current_class].to_s, :target => y[:parent_type].to_s  ,
      :strength =>15, :faveColor=> '#6FB1FC'}}
    }}.flatten.uniq

    {:nodes => nodes, :edges => edges}

  end

  def save_to_json(file, h)
    File.open(file, "w") do |f|
      f.write(h.to_json)
    end
  end
end
