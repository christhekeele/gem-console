require 'rake'
require "gem/console/version"

module Gem
  module Console

    class << self

      def enable(library_load_file = $library_load_file)

        library_load_file ||= catch(:file) do
          throw_or_recurse Dir[File.join 'lib', '*']
        end

        desc 'Open a console preloaded with this library'
        task :console, :cmd do |_, args|
          args.with_defaults(cmd: pry_enabled? ? 'pry' : 'irb')
          sh [
            'bundle exec',
            args.cmd,
            "-I lib",
            "-r #{library_load_file}"
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
          throw_or_recurse Dir[dir]
        end if not dirs.empty?
        raise 'No library file to load `rake console` from found.' +
          'Set $library_load_file in your Rakefile or ' +
          'provide a path in your `Gem::Console.enable` invocation.'
      end

      def pry_enabled?
        begin
          require 'pry'
        rescue LoadError
          false
        end
      end

    end

  end
end
