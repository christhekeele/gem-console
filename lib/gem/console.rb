require 'rake' unless defined? Rake

module Gem
  module Console

    extend Rake::DSL

    class << self

      def enable(load_dir = 'lib', load_file = nil)

        load_dir, load_file = 'lib', load_dir unless load_file or load_dir == 'lib'

        load_file ||= catch(:file) do
          search_gem_paths Dir[File.join load_dir, '*']
        end
        load_file.slice!(File.join load_dir, '')

        desc "Open a ruby console preloaded with this library"
        task :console do
          Rake::Task["console:#{command}"].invoke
        end

        namespace :console do

          task :irb do
            run_console precommand, :irb, load_dir, load_file
          end

          task :pry do
            run_console precommand, :pry, load_dir, load_file
          end

        end

      end

    private

      def search_gem_paths(paths)
        files, dirs = paths.partition do |path|
          File.file? path
        end
        files.each do |file|
          throw :file, file if File.extname(file) == '.rb'
        end if not files.empty?
        dirs.each do |dir|
          search_gem_paths Dir[File.join dir, '*']
        end if not dirs.empty?
        raise [
          'No library file to load `rake console` from found.',
          'Provide a path in your `Gem::Console.enable` invocation.',
        ].join(' ')
      end

      def precommand
        'bundle exec' if File.exists? 'Gemfile'
      end

      def command
        pry_enabled? ? :pry : :irb
      end

      def pry_enabled?
        require 'pry' or true
      rescue ::LoadError
        false
      end

      def run_console(precommand, command, load_dir, load_file)
        sh [
          'CONSOLE=true',
          precommand,
          command,
          "-I #{load_dir}",
          "-r #{load_file}",
        ].compact.join(' ')
      end

    end

  end
end
