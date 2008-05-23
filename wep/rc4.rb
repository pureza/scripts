class RC4
    def initialize(key = nil)
        @state = (0 .. 255).to_a   # Initialize state array with values 0 .. 255
        @x = @y = 0                # Our indexes. x, y instead of i, j
        setup(key) if key
    end

    # KSA
    def setup(key)
        for i in 0 .. 255
            @x = (key[i % key.length] + @state[i] + @x) & 0xFF
            @state[i], @state[@x] = @state[@x], @state[i]
        end
        @x = 0
    end
            
    # PRGA
    def crypt(input)
        output = [nil] * input.length

        for i in 0 .. input.length - 1
            @x = (@x + 1) & 0xFF
            @y = (@state[@x] + @y) & 0xFF
            @state[@x], @state[@y] = @state[@y], @state[@x]

            output[i] = (input[i] ^ @state[(@state[@x] + @state[@y]) & 0xFF]).chr
        end
        
        return output.join("").unpack("H*")
    end
end            


