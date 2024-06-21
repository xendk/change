require "./change/**"

# This is small helper tool for creating releases.
module Change
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
