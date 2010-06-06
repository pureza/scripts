#! /usr/bin/env ruby

to_remove = ARGV[0]
to_add    = ARGV[1]

apply = ARGV.length > 2

Dir["**/*.*"].sort.each do |path|
    begin
        name = File.basename(path)
        dirname = File.dirname(path)
        if name.include?(to_remove)
          new_name = name.gsub(to_remove, to_add)
          printf "%-80s  %s\n", name, new_name
        
          new_path = File.join(dirname, new_name)
          File.rename(path, new_path) if apply
        end
    rescue
    end
end
