# bundle-source-pathext [ ![](https://img.shields.io/gem/v/bundle-source-pathext.svg)](https://rubygems.org/gems/bundle-source-pathext) [ ![](https://img.shields.io/gem/dt/bundle-source-pathext.svg)](https://rubygems.org/gems/bundle-source-pathext)

This bundler plugin allows building local Ruby extensions that are referred to by a local path, similar to how gems are built when they are fetched from a remote path.

Rubygems/Bundler itself unfortunately does not build local extensions automatically, making workflows complicated that utilize gems with an extension build, as part of an application.

## Usage

In your Gemfile, replace something like `gem 'mygem', path: './folder` with:

```ruby
source './folder', type: 'pathext' do
  gem 'mygem'
end
```

Different from Rubygems, this plugin will prefer `rake compile` when an extension has a Rakefile, only falling back to the [Gem::Ext::Builder](https://github.com/ruby/rubygems/blob/master/lib/rubygems/ext/builder.rb) (or [other builders](https://github.com/ruby/rubygems/blob/master/lib/rubygems/ext/builder.rb#L173)) if needed. This is aimed at making debugging easier.

## LICENSE

Licensed under the 3-clause BSD license, see LICENSE file for details.

Copyright (c) 2026, pganalyze Team <team@pganalyze.com>
All rights reserved.
