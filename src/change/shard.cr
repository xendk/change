module Change
  class Shard
    # Raised on badly formatted shards file.
    class FormatError < Exception end

    @shard : Array(String)
    @version_index : Int32

    def initialize(shard : String)
      @shard = shard.split('\n')

      index = @shard.index do |line|
        line =~ /^version:/
      end

      raise FormatError.new("No version found in shards.yml") unless index

      @version_index = index
    end

    def bump(version : String)
      @shard[@version_index] = "version: #{version}"
    end

    def to_s(io : IO)
      io << @shard.join('\n')
    end
  end
end
