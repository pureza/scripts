#! /usr/bin/env ruby

require 'net/http'
require 'uri'
require 'bus.rb'
require 'yaml'
require 'sqlite3'
require 'rexml/document'

include REXML

CONFIG_FILE = "config.yaml"

#
# Load the configuration
#
def load_configuration
  file = File.open(CONFIG_FILE)
  bus_id2name, = YAML::load_stream(file).documents
  file.close

  return bus_id2name
end

#
# Fetchs the bus' entire webpage, to parse later
#
def bus_page(id)
  url = URI.parse('http://www.smtuc.pt')
  results = Net::HTTP.start(url.host, url.port) do |http|
    http.get("/horario.php?id_linha=#{id}").body
  end
end

#
# Parses the schedule out of the raw html
# Returns a table (or a list of lists), where each row is a row of
# the original html and each column is an hour
#
def parse_schedule(html)
  table = html.scan(/<table.*?<\/table>/m).first
  
  slots = table.scan(/<td.*?><font.*?>(.*?)<\/td>/).inject([[]]) do |m, n| 
    m << [] if m[-1].length >= 20
    if n[0] =~ /(\d+)/          
      m[-1] << $1.to_i
    else
      m[-1] << nil
    end
    m
  end
  
  slots
end


#
# Gets the source and target of the bus
#
def parse_source_target(html)
  source_target = html.scan(/<p align="center"><font face="Arial" size="2"><b>(.*?)<\/b>/)[0..1]
  source = source_target[0].first.unpack("C*").pack("U*").strip
  target = source_target[1].first.unpack("C*").pack("U*").strip
  return source, target
end

#
# Gets the list of bus stops
#
def parse_bus_stops(html)
  table = html.scan(/<table.*?<\/table>/m).first

  bus_stops = []
  table.scan(/<p style=\".*?\"><font.*?>(.*?)<\/font><\/p>/).each do |stop|
    bus_stops << stop.first.unpack("C*").pack("U*").strip
  end

  bus_stops[0..-2]
end


# 
# Creates a new bus object from the parsed elements
#
def create_bus(id, bus_stops, from, to, raw_slots)
  bus = Bus.new(id, bus_stops, from, to)

  raw_slots.each_with_index do |line, index|
    line.each_with_index do |minute, hour|
      next if minute.nil?
      case index
      when (0..9)
        bus.source_target.add(:weekdays, hour + 5, minute)
      when (10..14)
        bus.source_target.add(:saturday, hour + 5, minute)
      when (15..19)
        bus.source_target.add(:sunday, hour + 5, minute)
      when (20..29)
        bus.target_source.add(:weekdays, hour + 5, minute)
      when (30..34)
        bus.target_source.add(:saturday, hour + 5, minute)
      when (35..39)
        bus.target_source.add(:sunday, hour + 5, minute)
      end
    end
  end

  bus
end


#
# Writes bus' data to a XML file
#
def bus_to_xml(bus)
  
  def build_schedule_element(bus, from, to, days_of_week, table)
    schedule_tag = Element.new "schedule"
    schedule_tag.attributes["from"] = from
    schedule_tag.attributes["to"] = to
    schedule_tag.attributes["when"] = days_of_week
    
    table.keys.sort.each do |hour|
      mins = table[hour].sort
      for min in mins
        schedule_tag << at_tag = Element.new("at").add_text("%02d:%02d" % [hour, min])
      end
    end
    
    schedule_tag
  end

  doc = Document.new

  # <bus id="34" from="Universidade" to="Polo II">
  root = Element.new "bus"
  root.attributes["id"] = bus.id
  root.attributes["from"] = bus.from
  root.attributes["to"] = bus.to

  # <bus-stops>
  bus_stops_tag = Element.new "bus-stops"
  for bus_stop in bus.stops
    # <bus-stop>B. Norton de Matos</bus-stop>
    bus_stops_tag << Element.new("bus-stop").add_text(bus_stop)
  end

  root << bus_stops_tag

  # <schedule from="Universidade" to="Polo II" when="weekdays">
  #   <at> 10:30 </at>
  # </schedule>

  # weekdays, from source to target
  root << build_schedule_element(bus, bus.from, bus.to, "weekdays", bus.source_target.weekdays_table)
  # saturdays, from source to target
  root << build_schedule_element(bus, bus.from, bus.to, "saturday", bus.source_target.saturday_table)
  # sundays, from source to target
  root << build_schedule_element(bus, bus.from, bus.to, "sunday", bus.source_target.sunday_table)
  # weekdays, from target to source
  root << build_schedule_element(bus, bus.to, bus.from, "weekdays", bus.target_source.weekdays_table)
  # saturdays, from target to source
  root << build_schedule_element(bus, bus.to, bus.from, "saturday", bus.target_source.saturday_table)
  # sundays, from target to source
  root << build_schedule_element(bus, bus.to, bus.from, "sunday", bus.target_source.sunday_table)

  doc << root
  doc << XMLDecl.new
  doc
end


if ARGV.length != 1
  puts "Usage: #{$0} <bus name>"
  exit
end

BUS_NAME2ID = load_configuration()

bus = ARGV[0].upcase
bus_id = BUS_NAME2ID[bus]

if bus_id.nil?
  puts "Unknown bus: #{bus}"
  puts "Known buses: #{BUS_NAME2ID.keys.sort.join(" ")}"
  exit
end

# Fetch schedule data from www.smtuc.pt
body = bus_page(bus_id)

# Parse bus fields
source, target = parse_source_target(body)
slots = parse_schedule(body)
bus_stops = parse_bus_stops(body)

# Create the bus object
bus = create_bus(bus, bus_stops, source, target, slots)

# Create the XML document
File.open("#{bus.id}.xml", "w") do |fx|
  bus_to_xml(bus).write(fx, 1)
end
