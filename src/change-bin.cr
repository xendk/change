require "option_parser"
require "./change"

# Tell git not to use a pager.
ENV["GIT_PAGER"] = "cat"

command = :main
dry_run = false
OptionParser.parse do |parser|
  parser.banner = <<-EOS
Usage: #{PROGRAM_NAME} [<version>|create]

Update CHANGELOG.md and shard.yml with a new version, git add and commit
the new version and tag the new release. If no version is given, take it
from the unreleased header.

If the current dir has a GitHub origin, releases will be linked to
Github diffs.
EOS

  parser.on("-n", "--dry-run", "Simulate run") do
    dry_run = true
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.on("create", "Create CHANGELOG.md") do
    command = :create
    parser.banner = <<-EOS
Usage: #{PROGRAM_NAME} create

Creates an CHANGELOG.md file.

EOS
  end
end

cli = Change::Cli.new()

case command
when :main
  cli.update ARGV[0]?, dry_run
when :create
  cli.create_changelog ARGV[0]?
end
