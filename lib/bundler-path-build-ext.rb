require "bundler-path-build-ext/version"

Bundler::Plugin.add_hook(Bundler::Plugin::Events::GEM_AFTER_INSTALL) do |spec_install|
  spec = spec_install.spec
  if spec.source.instance_of?(Bundler::Source::Path) && !spec.extensions.empty?
    puts format('Building native extensions for %s %s in source tree at %s', spec.name, spec.version, spec.source.expanded_original_path)

    # If our current Bundler root path is identical with the base dir, add a "tmp/" directory to place extension build results in
    if spec.base_dir == Bundler.root
      spec.base_dir = File.join(spec.base_dir, 'tmp')
      # Reset cached values for extension_dir (which is derived from base_dir)
      spec.extension_dir = nil
      spec.instance_variable_set(:@bundler_extension_dir, nil) # see bundler/lib/bundler/rubygems_ext.rb
    end

    # Build and install extensions
    #
    # This already gets called with disable_extensions: true by the path source, but we need
    # the extensions to be built and installed.
    installer = Bundler::Source::Path::Installer.new(
      spec,
      env_shebang: false,
      disable_extensions: false,
      build_args: nil
    )
    installer.post_install
  end
end
