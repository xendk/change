# Change

Small tool to automate creation of Crystal shards and apps releases.

Change updates `CHANGELOG.md` and `shard.yml`, commits it and tags it.
It doesn't push it which allows you to give it the final eyeball.

## Installation

Change can be installed as a development dependency:

```yaml
development_dependencies:
  change:
    github: xendk/change
```

Alternatively you can compile the binary and put it in your path.

## Usage

Creating a `CHANGELOG.md` can be done with `change create`.

While working on your project add changelog entries under the `###
Unreleased` header, following the format described in [keep a
changelog](https://keepachangelog.com).

When ready for a new release simply run `change 1.0.0` to create the
`1.0.0` release. You can run the program with `-n` to see what it will
do.

As a convenience, if the unrelased header is formatted as 

```yaml
## <version> - Unreleased
```

You do not need to supply a version to `change`, it'll use the version
from the header and make the next unreleased version the following
patch version.

The reasoning is that whether the next release will be a major, minor
or patch release is most present when adding the changelog entries,
and fixing the header at the same time is a way to record this.

## Contributing

1. Fork it (<https://github.com/xendk/change/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Thomas Fini Hansen](https://github.com/xendk) - creator and maintainer
