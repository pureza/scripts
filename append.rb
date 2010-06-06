#! /usr/bin/env ruby

filter    = ARGV[0]
to_add    = ARGV[1]

apply = ARGV.length > 2

Dir["**/*.*"].sort.each do |path|
    begin
        name = File.basename(path)
        dirname = File.dirname(path)

        if name.include?(filter)
          new_name = to_add + name
          printf "%-80s  %s\n", name, new_name
        
          new_path = File.join(dirname, new_name)
          File.rename(path, new_path) if apply
        end
    rescue
    end
end
