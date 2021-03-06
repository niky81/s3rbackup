#!/usr/bin/ruby

require 'rubygems'
require 'optparse'

development_lib = File.join(File.dirname(__FILE__), '..', 'lib')
if File.exists? development_lib + '/s3dbsync.rb'
  $LOAD_PATH.unshift(development_lib).uniq!
end
# always look "here" for include files (thanks aktxyz)
#$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) 
require 's3dbsync'


class OptS3rquery
	def self.parse(args)
		options = {}
		opts = OptionParser.new do |opts|
			opts.banner = "Usage: s3query.rb [options] <search|get|unpack|delete|stats|delete_older> <parameters> (parameters can be name=test or simply test)"
		
			opts.on("-s", "search words", String, "Search something") do |name|
				options[:op] = "search"
			end
		
			opts.on("-n", "--name [NAME]", String, "Backup name") do |name|
				options[:name] = name
			end
		
			opts.on("-b", "--bucket BUCKET", String, "Bucket name") do |bucket|
				options[:bucket] = bucket
			end
		
			opts.on("-d", "--description DESCRIPTION", String, "Description") do |name|
				options[:descr] = name
			end
			
			opts.on("-c", "--file-cfg PATH", String, "Path of cfg file") do |name|
				options[:file_cfg] = name
			end

			opts.on("-l", "--output-cols COLS,COLS...", String, "Column of output") do |name|
				options[:cols] = name.split(",")
			end

			opts.on("-o", "--output-dir DIR", String, "When get or unpack this specifies the output directory") do |name|
				options[:out_dir] = name
			end
	
			opts.on("--newer", "Get only the newest item, with the same name") do |name|
				options[:newer] = true
			end
	
			opts.on("--older", "Get only the oldest item, with the same name") do |name|
				options[:older] = true
			end
	
			opts.on("--last", "Get only the newest item (only one result)") do |name|
				options[:last] = true
			end
	
			opts.on("--first", "Get only the oldest item (only one result)") do |name|
				options[:first] = true
			end

			opts.on("--per-bucket", "Get results grouped per bucket") do |name|
				options[:first] = true
			end

			opts.on("--detail", "Detailed output (stats)") do |name|
				options[:detail] = true
			end
	
			opts.on("--size", "Get size") do |name|
				options[:first] = true
			end
	
			opts.on("-u", "--config-number NUM", Integer, "Number of config to use if nil use first") do |name|
				options[:config_num] = name
			end
			
			opts.on("-e", "--item-to-keep NUM", Integer, "Number of item to keep after deleting the olders (delete_older)") do |name|
				options[:delete_older] = name
			end
			
			opts.on("--initialize", "Inizializza bucket and db") do |name|
				options[:initialize] = true
			end
			
			opts.on("--destroy", "Destroy bucket and db") do |name|
				options[:destroy] = true
			end
			
			opts.on("--test", "Test something") do |name|
				options[:test] = true
			end
			
			opts.on("--files", "Get files list") do |name|
				options[:files] = true
			end
			
			opts.on("--inside", "Search inside files, only start_with") do |name|
				options[:inside] = true
			end
			
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end
		end #.parse!
		opts.parse!(args)
		options
	end
end

def get_last(res)
	ret = []
	ret << res[res.nitems - 1] if res.nitems > 0
	ret
end

def get_first(res)
	ret = []
	ret << res[0] if res.nitems > 0
	ret
end

options = OptS3rquery.parse(ARGV)

config = Configure.new(options[:file_cfg], options[:config_num])
config.current["bucket"] = options[:bucket] if options[:bucket]

s3db = S3SyncDb.new(config.current)

command = ARGV.shift
case command
	when /[search|get|unpack|delete|stats|delete_older]/
		results = s3db.find(ARGV, nil, options)
		results = get_last(results) if options[:last]
		results = get_first(results) if options[:first]
end
case command
	when 'search'
		#cerca
		results.each do |ret|
			if options[:cols]
				outp = []
				options[:cols].each do |col|
					outp << ret[col]
				end
				puts outp.join("\t")
			else
				puts "#{ret["aws_name"]}\t#{ret["description"]}"
			end
		end
	when 'get'
		#scarica
		results.each do |ret|
			puts "Downloading of #{ret["aws_name"]}"
			s3db.get(ret, ret["aws_name"])
		end
	when 'unpack'
		#estrai nella dir
		results.each do |ret|
			puts "Unpacking of #{ret["aws_name"]}"
			s3db.unpack(ret, options[:out_dir])
		end
	when 'delete'
		#cancella
		results.each do |ret|
			puts "Deleting of #{ret["aws_name"]}"
			s3db.delete(ret)
		end
	when 'delete_older'
		#cancella i piu' vecchi mantenendo options[:delete_older] item
		# per ongi nome trovato
		if options[:delete_older] == nil
			options[:delete_older] = 2
		end
		group = {}
		results.each do |ret|
			group[ret["name"]] ||= []
			group[ret["name"]] << ret
		end
		group.each do |key, arr_ret|
			arr_ret.sort! {|x,y| x["datetime"] <=> y["datetime"] }
			options[:delete_older].times do |num|
				arr_ret.pop
			end 
			arr_ret.each do |ret|
				puts "Deleting of #{ret["aws_name"]}"
				s3db.delete(ret)
			end
		end
	when 'stats'
		#get size
		bucks_s = {}
		if options[:detail]
			results.each do |ret|
				puts "#{ret["name"]}\t#{sprintf("%.2fMb", ret["size"].to_i / (1024.0 * 1024.0))}"
			end
		else
			results.each do |ret|
				bucks_s[ret["bucket"]] ||= 0
				bucks_s[ret["bucket"]] += ret["size"].to_i
			end
			bucks_s.each do |key,val|
				puts "#{key}:\t#{sprintf("%.2fMb", val / (1024.0 * 1024.0))}"
			end
		end
	else
		if options[:initialize]
			s3db.initialize_db
		elsif	options[:destroy]
			s3db.destroy_db
		elsif options[:test]
			s3db.test
		else
			puts "Some error occurred command #{command} not valid"
		end
end

