require "semantic_version"

module Change
  class Changelog
    # Raised on badly formatted changelogs.
    class FormatError < Exception end

    # Raised on un-parsable version headers.
    class MalformedVersionHeader < Exception end

    # Raised when no version in the unreleased header.
    class NoHeaderVersion < Exception end

    LINKS_SEPARATOR = "<!-- links -->"
    UNRELEASED_RE = /^## ([^ ]+ - )?\[?Unreleased\]?/

    @changelog : Array(String)
    @links : Array(String)?
    @unreleased_index : Int32
    @unreleased_version : String?

    def initialize(changelog : String, @repo : String? = nil)
      parts = changelog.split(LINKS_SEPARATOR)
      @changelog, @links = parts[0].split('\n'), parts[1]?.try &.split('\n')

      count = @changelog.count { |line| line =~ UNRELEASED_RE }
      raise FormatError.new("Multiple unreleased sections in changelog") if count > 1
      raise FormatError.new("No unreleased section in changelog") if count < 1

      # Find unreleased section.
      index = @changelog.index do |line|
        line =~ UNRELEASED_RE
      end

      raise FormatError.new("No unreleased section in changelog") unless index

      unlinkify

      @unreleased_version = Changelog.extract_version(@changelog[index]) rescue nil
      @unreleased_version = nil if @unreleased_version == "Unreleased"
      @unreleased_index = index
    end

    def self.create(repo : String? = nil) : self
      content = String.build do |str|
        str << <<-CHANGELOG
            # Changelog

            All notable changes to this project will be documented in this file.

            The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
            and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

            ## 0.1.0 - Unreleased

            ### Added
            - Initial version.

            CHANGELOG
      end

      new content, repo
    end

    def self.extract_version(header : String) : String
      raise MalformedVersionHeader.new("Malformed version header: #{header}") unless /^## \[?([^] ]+)/ =~ header
      $1
    end

    def releases
      # We don't sort the versions as we assume the file order should
      # be correct.
      @changelog.select do |line|
        /^## / =~ line && /Unreleased/ !~ line
      end.map { |header| SemanticVersion.parse(Changelog.extract_version(header)) }
    end

    def bump(version : String? = nil, date : Time = Time.local)
      # Rewrite the unreleased header if it contains a version.
      if unreleased_version = @unreleased_version
        if version
          @changelog[@unreleased_index] = "## Unreleased"
        else
          version = unreleased_version
          new_unreleased = SemanticVersion.parse(version).bump_patch
          @changelog[@unreleased_index] = "## #{new_unreleased} - Unreleased"
        end
      else
        if !version
          raise NoHeaderVersion.new("No version in unreleased header")
        end
      end

      @changelog.insert(@unreleased_index + 1, "## #{version} - #{date.to_s("%Y-%m-%d")}")
      @changelog.insert(@unreleased_index + 1, "")

      version
    end

    # Remove links from release headers.
    def unlinkify
      @changelog.each_with_index do |line, index|
        if /^## / =~ line
          @changelog[index] = line.gsub(/\[(.*)\]/, "\\1")
        end
      end
    end

    # Add links to release headers.
    def linkify : Array(String)
      @changelog.map do |line|
        if /^## / =~ line
          if /Unreleased/ =~ line
            line = line.gsub(/Unreleased/, "[Unreleased]")
          else
            line = line.gsub(/^## ([^ ]+)/, "## [\\1]")
          end
        end

        line
      end
    end

    def to_s(io : IO)
      versions = [] of String
      if repo = @repo
        versions = releases
      end

      if repo && !versions.empty?
        io << linkify.join('\n')
      else
        io << @changelog.join('\n')
      end

      if repo && !versions.empty?
        io << LINKS_SEPARATOR
        io << '\n'
        io << "[Unreleased]: https://github.com/#{repo}/compare/v#{versions[0]}...HEAD"
        io << '\n'
        versions.each_with_index do |version, index|
          prev_version = versions[index + 1]?
          io << (prev_version ? "[#{version}]: https://github.com/#{repo}/compare/v#{prev_version}...v#{version}" : "[#{version}]: https://github.com/#{repo}/releases/tag/v#{version}")
          io << '\n'
        end
      end
    end
  end
end
