require 'rake'
require "gem/console/version"

module Gem
  module Console

    extend Rake::DSL

    class << self

      def enable(load_dir = 'lib', load_file = nil)

        load_dir, load_file = 'lib', load_dir unless load_file

        load_file ||= catch(:file) do
          throw_or_recurse Dir[File.join load_dir, '*']
        end
        load_file.slice!(File.join load_dir, '')

        desc "Open a ruby console preloaded with this library"
        task :console, :cmd do |_, args|
          args.with_defaults(cmd: pry_enabled? ? 'pry' : 'irb')
          sh [
            'bundle exec',
            args.cmd,
            "-I #{load_dir}",
            "-r #{load_file}"
          ].join(' ')
        end

      end

    private

      def throw_or_recurse(paths)
        files, dirs = paths.partition do |path|
          File.file? path
        end
        files.each do |file|
          throw :file, file if File.extname(file) == '.rb'
        end if not files.empty?
        dirs.each do |dir|
          throw_or_recurse Dir[File.join dir, '*']
        end if not dirs.empty?
        raise [
          'No library file to load `rake console` from found.',
          'Provide a path in your `Gem::Console.enable` invocation.',
        ].join(' ')
      end

      def pry_enabled?
        require 'pry' or true
      rescue ::LoadError
        false
      end

    end

  end
end
