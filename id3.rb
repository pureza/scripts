#! /usr/bin/env ruby

require 'rubygems'
require 'id3lib'
require 'optparse'

def infoFromFileName(name)
    artist, year, album = (File.dirname name).scan(/\/([^\/]*)\/(\d+)\ -\ ([^\/]*)$/)[0]
    track, title = (File.basename name).scan(/(\d+) - (.*).mp3$/)[0]
    { :title => title, :artist => artist, :album => album, :year => year, :track => track }
end


options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: fill_id3.rb [-a]"

    opts.on("-a", "--apply", "Apply changes") do |v|
        options[:apply] = v
    end
end.parse!




Dir["**/*.mp3"].sort.each do |path|
    begin
        info = infoFromFileName(File.expand_path(path))
        printf "%-3s %-70s %-40s %-45s %-4s\n", info[:track], info[:title], info[:artist], info[:album], info[:year]

        if options[:apply]
          tag = ID3Lib::Tag.new(path)
          tag.title = info[:title]
          tag.album = info[:album]
          tag.track = info[:track]
          tag.artist = info[:artist]
          tag.year = info[:year]
          tag.update!
        end
    end
end

