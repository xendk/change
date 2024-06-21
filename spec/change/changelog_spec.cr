require "../spec_helper"

include Change

describe Changelog do
  it "generates changelog" do
    changelog = Changelog.create.to_s

    changelog.should contain "# Changelog"
    changelog.should contain "## 0.1.0 - Unreleased"
    changelog.should contain "### Added"
    changelog.should contain "- Initial version"
  end

  it "should raise on multiple unreleased sections" do
    expect_raises(Changelog::FormatError) do
      Changelog.new <<-EOS
      ## Unreleased
      ## Unreleased
      EOS
    end
  end

  it "should raise on no unreleased section" do
    expect_raises(Changelog::FormatError) do
      Changelog.new <<-EOS
      ## 1.1.1
      EOS
    end
  end

  it "should handle different release headers" do
    Changelog.extract_version("## 1.2.3 - 2024-06-19").should eq "1.2.3"
    Changelog.extract_version("## [1.2.3] - 2024-06-19").should eq "1.2.3"
  end

  it "should bump version with explicit version" do
    changelog = Changelog.create

    changelog.bump("1.1.1", Time.local(2024, 6, 19))

    # With explicit version it shouldn't try to guess the next either.
    changelog.to_s.should contain <<-EOS
    ## Unreleased

    ## 1.1.1 - 2024-06-19

    ### Added
    - Initial version
    EOS

    # And again, without a version in the header.
    changelog = Changelog.new(Changelog.create.to_s.gsub(/\n## .*Unreleased.*\n/, "\n## Unreleased\n"))

    changelog.bump("1.1.1", Time.local(2024, 6, 19))

    changelog.to_s.should contain <<-EOS
    ## Unreleased

    ## 1.1.1 - 2024-06-19

    ### Added
    - Initial version
    EOS
  end

  it "should bump version with header version" do
    changelog = Changelog.create

    changelog.bump(date: Time.local(2024, 6, 19))

    changelog.to_s.should contain <<-EOS
    ## 0.1.1 - Unreleased

    ## 0.1.0 - 2024-06-19

    ### Added
    - Initial version
    EOS

    changelog = Changelog.new(Changelog.create.to_s.gsub(/\n## .*Unreleased.*\n/, "\n## Unreleased\n"))
    # And throw if no header version.
    expect_raises(Changelog::NoHeaderVersion) do
      changelog.bump(date: Time.local(2024, 6, 19))
    end
  end

  it "should update links section when bumping" do
    changelog = Changelog.create("xendk/check")

    changelog.bump("0.1.0", Time.local(2024, 6, 19))
    changelog.to_s.should contain <<-EOS
    [Unreleased]: https://github.com/xendk/check/compare/v0.1.0...HEAD
    [0.1.0]: https://github.com/xendk/check/releases/tag/v0.1.0
    EOS

    changelog.bump("0.2.0", Time.local(2024, 6, 22))
    changelog.to_s.should contain <<-EOS
    [Unreleased]: https://github.com/xendk/check/compare/v0.2.0...HEAD
    [0.2.0]: https://github.com/xendk/check/compare/v0.1.0...v0.2.0
    [0.1.0]: https://github.com/xendk/check/releases/tag/v0.1.0
    EOS
  end

  it "should linkify releases" do
    changelog = Changelog.create("xendk/check")

    changelog.bump("0.1.0", Time.local(2024, 6, 19))
    changelog.to_s.should contain <<-EOS
    ## [0.1.0] - 2024-06-19
    EOS
  end

  it "should unlinkify releases" do
    changelog = Changelog.create()

    changelog.bump("0.1.0", Time.local(2024, 6, 19))
    changelog = Changelog.new(changelog.to_s.gsub(/## 0.1.0/, "## [0.1.0]"))

    changelog.bump("0.2.0", Time.local(2024, 6, 22))
    changelog.to_s.should contain <<-EOS
    ## 0.1.0 - 2024-06-19
    EOS
  end
end
