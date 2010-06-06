#!/usr/bin/env ruby

require 'ieee80211.rb'
require 'pcaplet'

RADIOTAP_HEADER_LEN_BYTE = 2
WEP_KEY = ["F2A1C40A2B05C94C99C89D665E"].pack("H*")

# create a sniffer that grabs the first 1500 bytes of each packet
NETWORK = Pcaplet.new('-i at0 -s 1500')
NETWORK.add_filter(Pcap::Filter.new('', NETWORK.capture))

for packet in NETWORK
    bytes = packet.raw_data

    if bytes.length > 24
        packet_ieee = IEEE80211.new(bytes)
        dados = packet_ieee.wep_decrypt(WEP_KEY).pack("H*");

        packet.raw_data = dados

        p Pcap::TCPPacket.methods.sort

 #       tcp = Pcap::TCPPacket.new(packet)
#        p tcp

    end
end






