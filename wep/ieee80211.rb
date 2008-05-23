require 'rc4.rb'

class IEEE80211
    def initialize(bytes)
        @bytes = bytes
    end

    def wep_decrypt(key)
        z = ((@bytes[1] & 3) != 3) ? 24 : 30
        iv = @bytes[z .. z + 2]
        key = iv + key

        return RC4.new(key).crypt(@bytes[z + 4 .. -5])
    end
end
