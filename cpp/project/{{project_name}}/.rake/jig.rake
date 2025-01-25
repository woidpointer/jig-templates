# frozen_string_literal: true

namespace :jig do
  desc 'Commandline to create a application'
  task :app do
    puts 'jig create app <name> --target sources' if File.exist?('sources')
  end
  desc 'Commandline to create a ASMR application skeleton'
  task :amsr_app do
    puts 'jig create amsr-app <name> --target sources' if File.exist?('sources')
  end
  desc 'Commandline to create a library'
  task :lib do
    puts 'jig create lib <CamelCaseName> --target sources --namespace <name::space>' if File.exist?('sources')
  end
  desc 'Commandline to add a c++ class to the project'
  task :cpp do
    Dir.glob('sources/*') do |elem|
      puts "jig create cpp <CamelCaseName> --target #{elem} --namespace <name::space>" if File.directory?(elem)
    end
  end
end
