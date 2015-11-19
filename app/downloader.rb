require 'http'
require 'rubygems/package'
require 'open-uri'
require 'open_uri_redirections'
require 'fileutils'
require 'pp'

require __dir__ + "/scala_parser.rb"

class Downloader
  attr_reader :repo_path
  def initialize()
    #@repo_path = path
    @parser = ScalaParser.new
    @transformer = ScalaTransformer.new
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
    get_sources_for_archive(archive_name) do |name, file_contents|
      #puts name
      @transformer.apply(@parser.parse_file(file_contents))
    end
  end

  def get_sources_for_archive(archive_name, file_types = [".scala"])
    result = []
    File.open(archive_name, "rb") do |file|
      Zlib::GzipReader.wrap(file) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each do |entry|
            result << yield(entry.full_name, entry.read) if entry.file? and file_types.include? File.extname(entry.full_name)
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

  #helper method.returns all parent type names as list
  def process_variable(variable_info, parent)
    #puts "++++++++++++=="
    #puts variable_info
    if variable_info[:variable].is_a? Array
      variable_info[:variable].map{|x| {var: x, current: parent}}
    else
      []
    end
  end


  def process_class(class_info, parent)
    #puts class_info
    name = class_info[:name].to_s
    result = []
    result = [{inside: parent, current: name}] if parent.length >0
    if class_info[:parent]
      result  = class_info[:parent].map{|x| {parent:x, current: name}}
    end
    if class_info[:params]
      result << class_info[:params].flatten.map{|x| {param: x, current: name}}
    end
    if class_info[:optional_brackets]
      if class_info[:optional_brackets][:content]
        content = pp(class_info[:optional_brackets][:content])
        variables = content.select{|x| x[:variable] }.compact
        result << variables.map{|v| process_variable(v, name)}
        result << content.select{|x| x[:object] }.compact.map{|o| process_class(o[:object], name)}
        result << content.select{|x| x[:class] }.compact.map{|o| process_class(o[:class], name)}
        result << content.select{|x| x[:trait] }.compact.map{|o| process_class(o[:trait], name)}
      end
    end
    result.flatten.uniq
  end

  def process_pair(pair, hidden_types)
    return nil if hidden_types.include? pair[:current]
    return nil if hidden_types.include? pair[:param]
    return nil if hidden_types.include? pair[:var]
    return nil if hidden_types.include? pair[:parent]
    return nil if hidden_types.include? pair[:inside]
    if pair[:var]
      return {:data => {:source => pair[:current], :target => pair[:var],
      :strength => 25, :faveColor=> 'green'}}
    end
    if pair[:param]
      return {:data => {:source => pair[:current], :target => pair[:param],
      :strength => 15, :faveColor=> 'pink'}}
    end
    if pair[:parent]
      return {:data => {:source => pair[:current], :target => pair[:parent],
      :strength => 35, :faveColor=> '#6FB1FC'}}
    end
    if pair[:inside]
      return {:data => {:source => pair[:current], :target => pair[:inside],
      :strength => 45, :faveColor=> 'red'}}
    end
    nil
  end

  def get_type_info(h)
    return process_class(h[:class], "") if h[:class]
    return process_class(h[:object], "") if h[:object]
    return process_class(h[:trait], "") if h[:trait]
    []
  end
  def collect_from_hash(v)
    vv = v.flat_map{|x| x[:elements]}.compact
    parent_types = vv.flat_map{|x| x[:parent]}.compact.map{|x| x[:parent_type]}
    hidden_types= ["Seq", "Map", "Double", "String"]
    data = vv.flat_map{|x| get_type_info(x)}.compact
    node_names = data.map{|x| x.values}.flatten.uniq.delete_if{|x| x== "" || hidden_types.include?(x)}
    #parent_types = vv.flat_map{|x| x[:parent]}.compact.map{|x| x[:parent_type]}
    nodes = node_names.map{|x|
      {
        :data => {
          :id => x,
          :name => x,
          :weight => 45,
          :faveColor => 'navy',
          :faveShape => 'rectangle' #select_shape(x, classes, trait_names)
          }
      }
    }

    edges = data.map{|x| process_pair(x, hidden_types)}.compact.flatten.uniq

    {:nodes => nodes, :edges => edges}

  end

  def save_to_json(file, h)
    File.open(file, "w") do |f|
      f.write(h.to_json)
    end
  end
end
