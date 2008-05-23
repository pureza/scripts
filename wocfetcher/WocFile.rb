require 'digest/md5'

class WocFile

  attr_reader :name, :description, :size, :date, :url, :id

  def initialize(name, descritpion, size, date, url)
    @name = name
    @description = description
    @size = size
    @date = date
    @url = url
    
    url =~ /id=(\d+)/
    @id = $1.to_i
  end

  def to_md5
    Digest::MD5.hexdigest("#{@name}|#{@size}|#{@url}")
  end
end
