#!/usr/bin/env ruby

require 'pcaplet'

# create a sniffer that grabs the first 1500 bytes of each packet
NETWORK = Pcaplet.new('-i at0 -s 1500')

# create a filter that uses our query string and the sniffer we just made
HTTP_FILTER = Pcap::Filter.new('tcp and port http', NETWORK.capture)
MSNMS_FILTER = Pcap::Filter.new('tcp and port 1863', NETWORK.capture)

# add the new filter to the sniffer
NETWORK.add_filter(HTTP_FILTER | MSNMS_FILTER)

# Known MSN switchboard sessions
SESSIONS = Hash.new([])

# iterate over every packet that goes through the sniffer
for packet in NETWORK
    data = packet.tcp_data
    
    next unless data

    case packet
    when MSNMS_FILTER
        lines = data.split("\r\n")

        content_type_line = lines.find { |line| line =~ /Content-Type/ }

        if content_type_line.nil?
            case data
            when /IRO \d+ \d+ \d+ ([^\ ]+)/
                SESSIONS[packet.dport] << $1
            when /JOI ([^\ ]+)/
                SESSIONS[packet.dport] << $1
            end

            next
        end

        content_type = content_type_line.split[1]
        
        case content_type
        when "text/plain;"
            msg_line = lines.find { |line| line =~ /^MSG/ }
            msg_format_index = lines.find { |line| line =~ /^X-MMS-IM-Format:/ }
            
            msg_to = msg_line.split[1]
            if msg_to =~ /^\d+$/
                session_id = packet.sport
                
                if SESSIONS.has_key? session_id
                    print ">> (#{Time.now.strftime("%H:%M:%S")}) To: #{SESSIONS[session_id]}" 
                else
                    print ">> (#{Time.now.strftime("%H:%M:%S")}) To: #{packet.sport}" 
                end
            else
                session_id = packet.dport
                
                SESSIONS[session_id] = [] unless SESSIONS.has_key? session_id 
                SESSIONS[session_id]  << msg_to unless SESSIONS[session_id].include?(msg_to)
                
                print "\e[0;31m<< (#{Time.now.strftime("%H:%M:%S")}) From: #{msg_to}"
            end
            print "#{lines[lines.index(msg_format_index) + 1 .. -1].join("\n")}"
            puts "\e[0m"
        end
    end
end
