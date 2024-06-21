require "../spec_helper"

include Change

describe Shard do
  it "should replace shard version" do
    shard = Shard.new(<<-EOS)
    name: change
    version: 0.1.0
    EOS

    shard.bump("1.0.0").to_s.should contain "version: 1.0.0"
  end
  it "should error on missing version" do
    expect_raises(Shard::FormatError) do
      shard = Shard.new(<<-EOS)
      name: change
       version: 0.1.0
      EOS
    end
  end
end
