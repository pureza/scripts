#! /usr/bin/env ruby

apply = ARGV.length > 0

to_remove = "dream_theater-"

Dir["**/**.mp3"].sort.each do |path|
    begin
        dirname = File.dirname(path)
        name = File.basename(path)
        track, ignore, title = name.scan(/(\d+(x\d+)?)[^\w]*(.*)/).first
        new_title = title.gsub(to_remove, "").gsub(/_/, " ")
        new_title_cap = new_title.capitalize.gsub(/\bi\b/, "I")
        new_name = "#{track} - #{new_title_cap}"
        printf "%-80s  %s\n", name, new_name

        new_path = sprintf "%s/%s", dirname, new_name
        File.rename(path, new_path) if apply
    rescue
    end
end
