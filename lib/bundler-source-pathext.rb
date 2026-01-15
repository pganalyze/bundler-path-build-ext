require "bundler-source-pathext/version"

class BundlerSourcePathext < Bundler::Plugin::API
  class PathExtSource < Bundler::Source#Bundler::Source::Path
    def install(spec, opts)
      print_using_message "Using #{spec.name} #{spec.version} from #{self}"

      using_message = "Using #{version_message(spec, options[:previous_spec])} from #{self}"
      using_message += " and installing its executables" unless spec.executables.empty?
      print_using_message using_message
      generate_bin(spec, disable_extensions: true) # Turned off!

      build_local_extensions(spec)

      nil # no post-install message
    end

    # Bundler plugin api, we need to return a Bundler::Index
    def specs
      files = Dir.glob(File.join(File.expand_path(uri), '*.gemspec'))

      Bundler::Index.build do |index|
        files.each do |file|
          next unless spec = Bundler.load_gemspec(file)
          spec.installed_by_version = Gem::VERSION
          spec.source = self
          spec.extension_dir = File.join(File.dirname(file), 'tmp', RUBY_PLATFORM, spec.name, RUBY_VERSION)
          Bundler.rubygems.validate(spec)

          index << spec
        end
      end
    end

    # Set internal representation to fetch the gems/specs locally.
    #
    # When this is called, the source should try to fetch the specs and
    # install from the local system.
    def local!
      # not applicable
    end

    # Set internal representation to fetch the gems/specs from remote.
    #
    # When this is called, the source should try to fetch the specs and
    # install from remote path.
    def remote!
      # not applicable
    end

    # Set internal representation to fetch the gems/specs from app cache.
    #
    # When this is called, the source should try to fetch the specs and
    # install from the path provided by `app_cache_path`.
    def cached!
      # not applicable
    end

    # This is called to update the spec and installation.
    #
    # If the source plugin is loaded from lockfile or otherwise, it shall
    # refresh the cache/specs (e.g. git sources can make a fresh clone).
    def unlock!
      # not applicable
    end

    private

    def build_local_extensions(spec)
      build_args = options[:build_args] || Bundler.rubygems.build_args || begin
        require_relative "command"
        Gem::Command.build_args
      end

      builder = Gem::Ext::Builder.new spec, build_args

      build_extensions(spec, build_args, builder)
    end

    def build_extensions(spec, build_args, builder)
      return if spec.extensions.empty?

      if build_args.empty?
        puts "Building native extensions for #{spec.name}. This could take a while..."
      else
        puts "Building native extensions for #{spec.name} with: '#{@build_args.join " "}'"
        puts "This could take a while..."
      end

      dest_path = spec.extension_dir
      start = Time.now
      load_dir = File.dirname(spec.loaded_from)

      success = true
      spec.extensions.each do |extension|
        if extension[/extconf/] && File.exist?(File.join(load_dir, 'Rakefile'))
          rake_args = ['compile']
          builder.class.run(rake + rake_args, [], 'rake compile (via ' + self.class.to_s + ')', load_dir) do |status, results|
            unless status.success?
              success = false
              puts results
            end
          end
        else
          builder.build_extension extension, dest_path
        end
      end
      puts format('  Finished after %0.2f seconds', Time.now - start)
      FileUtils.touch(spec.gem_build_complete_path) if success
    end

    def rake
      rake = ENV["rake"]

      if rake
        rake = Shellwords.split(rake)
      else
        begin
          rake = Gem::Ext::Builder.ruby << "-rrubygems" << Gem.bin_path("rake", "rake")
        rescue Gem::Exception
          rake = [Gem.default_exec_format % "rake"]
        end
      end
      rake
    end

    def generate_bin(spec, options = {})
      gem_dir = Pathname.new(spec.full_gem_path)

      # Some gem authors put absolute paths in their gemspec
      # and we have to save them from themselves
      spec.files = spec.files.filter_map do |path|
        next path unless /\A#{Pathname::SEPARATOR_PAT}/o.match?(path)
        next if File.directory?(path)
        begin
          Pathname.new(path).relative_path_from(gem_dir).to_s
        rescue ArgumentError
          path
        end
      end

      installer = Path::Installer.new(
        spec,
        env_shebang: false,
        disable_extensions: options[:disable_extensions],
        build_args: options[:build_args],
        bundler_extension_cache_path: extension_cache_path(spec)
      )
      installer.post_install
    rescue Gem::InvalidSpecificationException => e
      Bundler.ui.warn "\n#{spec.name} at #{spec.full_gem_path} did not have a valid gemspec.\n" \
                      "This prevents bundler from installing bins or native extensions, but " \
                      "that may not affect its functionality."

      if !spec.extensions.empty? && !spec.email.empty?
        Bundler.ui.warn "If you need to use this package without installing it from a gem " \
                        "repository, please contact #{spec.email} and ask them " \
                        "to modify their .gemspec so it can work with `gem build`."
      end

      Bundler.ui.warn "The validation message from RubyGems was:\n  #{e.message}"
    end
  end

  source 'pathext', PathExtSource
end
