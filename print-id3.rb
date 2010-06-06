#! /usr/bin/env ruby

require 'rubygems'
require 'id3lib'

Dir["**/*.mp3"].sort.each do |path|
    begin
        tag = ID3Lib::Tag.new(path)

        printf "%-3s %-70s %-40s %-45s %-4s\n", tag.track, tag.title, tag.artist, tag.album, tag.year
    end
end

