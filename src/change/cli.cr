require "colorize"

module Change
  class Cli
    CHANGELOG = "CHANGELOG.md"
    SHARD = "shard.yml"

    def create_changelog(repo : String?)
      File.write(CHANGELOG, Changelog.create(repo).to_s)
    end

    def update(version : String? = nil, dry_run : Bool = false)
      # TODO:
      # - sh: git diff --exit-code
      # msg: Unstaged changes present
      # - sh: git diff --cached --exit-code
      # msg: Staged changes present

      exit! "Could not find #{CHANGELOG}" unless File.exists? CHANGELOG
      exit! "Could not find #{SHARD}" unless File.exists? SHARD

      changelog = Changelog.new(File.read(CHANGELOG), repo)
      shard = Shard.new(File.read(SHARD))

      begin
        version = changelog.bump version
        shard.bump version
      rescue ex
        exit! ex.message || "Unknown error"
      end

      if dry_run
        show_diff(changelog, CHANGELOG)
        show_diff(shard, SHARD)
      else
        File.write(CHANGELOG, changelog.to_s)
        File.write(SHARD, shard.to_s)
      end

      run("git", ["add", CHANGELOG, SHARD], dry_run)
      run("git", ["commit", "-m\"Preparing release #{version}\""], dry_run)
      run("git", ["tag", "v#{version}", "-a", "-m\"Release #{version}\""], dry_run)
    end

    def show_diff(content, file : String)
      tempfile = File.tempfile(file) do |file|
        file.print(content)
      end

      Process.run("git", ["diff", "--no-index", file, tempfile.path], output: :inherit)
      tempfile.delete
    end

    def run(command : String, args : Array(String), dry_run : Bool)
      unless dry_run
        Process.run(command, args, output: :inherit)
      else
        puts "Would run \"#{command} #{args.join(' ')}\""
      end
    end

    def repo
      output = `git remote get-url origin`

      repo = nil
      if $?.success?
        repo = $1 if /^git@github.com:(.*).git$/ =~ output.strip
      end

      repo
    end

    # Print message and exit with non-zero exit code.
    def exit!(message : String)
      STDERR.puts "#{"Error".colorize(:red)}: #{message}"
      exit 1
    end
  end
end
