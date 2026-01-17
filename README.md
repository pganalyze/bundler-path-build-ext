# bundler-source-pathext [ ![](https://img.shields.io/gem/v/bundler-source-pathext.svg)](https://rubygems.org/gems/bundler-source-pathext) [ ![](https://img.shields.io/gem/dt/bundler-source-pathext.svg)](https://rubygems.org/gems/bundler-source-pathext)

This bundler plugin allows building local Ruby extensions that are referred to by a local path, similar to how gems are built when they are fetched from a remote path.

Rubygems/Bundler itself unfortunately does not build local extensions automatically, making workflows complicated that utilize gems with an extension build, as part of an application.

## Usage

In your Gemfile, replace something like `gem 'mygem', path: './folder` with:

```ruby
source './folder', type: 'pathext' do
  gem 'mygem'
end
```

Different from Rubygems, this plugin uses a modified version of [Gem::Ext::Builder](https://github.com/ruby/rubygems/blob/master/lib/rubygems/ext/builder.rb) for Ruby extensions with an "extconf" folder, that does not create an additional copy of the created binaries in the extension install folder. This is done to avoid caching issues where the version in the extension install folder gets stale.

## LICENSE

Licensed under the 3-clause BSD license, see LICENSE file for details.

Copyright (c) 2026, pganalyze Team <team@pganalyze.com>
All rights reserved.
