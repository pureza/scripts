require 'net/http'
require 'net/https'
require 'uri'

require 'WocFile'

class WocDiscipline

    def initialize(name)
        @name = name
        @id = COURSES_TABLE[name.downcase]

        raise "Unknown course" if @id.nil?
    end

    def each_file(path)
        http = Net::HTTP.new(URL, 443)
        http.use_ssl = true

        response, data = http.get(path, {'Cookie' => $cookie})

        # For material
        regexp = /<tr>\s*?<td class = \"cellcontent\" >.*?<\/tr>\s*?<tr>.*?<\/tr>\s*?<tr>.*?<\/tr>\s*?<tr>.*?<\/tr>/m
        data.scan(regexp) do |section|
            title = extract_title(section)
            description = extract_description(section)
            url = extract_download_url(section)
            size = extract_size(section)
            date = extract_date(section)

            yield WocFile.new(title, description, size, date, url)
        end

        # For projects
        regexp2 = /<tr>\s*?<td class = \"cellcontent\">.*?<\/tr>\s*?<tr>.*?<\/tr>\s*?<tr>\s*?<td>\s*?<table.*?<\/table>\s*?<\/td>\s*?<\/tr>\s*?<tr>.*?<\/tr>/m
        data.scan(regexp2) do |section|
            title = extract_title(section)
            description = extract_description2(section)
            url = extract_download_url(section)
            size = extract_size(section)
            date = extract_date(section)

            yield WocFile.new(title, description, size, date, url)
        end

        # For assessment material
        regexp = /<tr class = \"cellcontent\".*?>.*?<\/tr>\s*?<tr>.*?<\/tr>\s*?<tr>.*?<\/tr>\s*?<tr>.*?<\/tr>/m
        data.scan(regexp) do |section|
            title = extract_title(section)
            description = extract_description(section)
            url = extract_download_url(section)
            size = extract_size(section)
            date = extract_date(section)
            yield WocFile.new(title, description, size, date, url)
        end
    end

    def each_material
        each_file("/weboncampus/class/getmaterial.do?idclass=#{@id}") { |file| yield file }
    end

    def each_project
        each_file("/weboncampus/class/getprojects.do?idclass=#{@id}") { |file| yield file }
    end

    def each_assessment
        each_file("/weboncampus/class/getmaterialavaliation.do?idclass=#{@id}") { |file| yield file }
    end

    def extract_title(section)
        regexp = /<tr.*?\"cellcontent\".*?>.*?<strong>(.*?)<\/strong>/m

        section =~ regexp
        $1.unpack("C*").pack("U*")
    end

    def extract_description(section)
        regexp = /<tr>.*?<\/tr>.*?<tr>.*?<\/tr>.*?<tr>\s*?<td>\s*?(.*?)\s*?<\/td>\s*?<\/tr>/m

        section =~ regexp
        $1.unpack("C*").pack("U*").strip
    end

    def extract_description2(section)
        regexp = /<tr>.*?<\/tr>.*?<tr>\s*?<td>\s*?(.*?)\s*?<\/td>\s*?<\/tr>/m

        section =~ regexp
        $1.unpack("C*").pack("U*").strip
    end

    def extract_download_url(section)
        regexp = /<a href="(.*?)">download<\/a>/m
        section =~ regexp

        $1
    end

    def extract_size(section)
        regexp = /tamanho: (\d+\.\d+)/im
        section =~ regexp
        
        $1
    end

    def extract_date(section)
        regexp = /(\d{4}-\d{2}-\d{2})/im
        section =~ regexp

        $1
    end

end
