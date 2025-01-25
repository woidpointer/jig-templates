# frozen_string_literal: true

require 'json'

def build_conan_install(cfg)
  cmd = []
  cmd << 'conan install'
  cmd << '.'
  cmd << "--output-folder=#{build_dir}"
  cmd << "-pr:a=#{workdir}/.conan/#{cfg['compiler']}__#{cfg['triplet']}"
  cmd << "-s build_type=#{cfg['type']}"
  cmd << '--build missing'
  sh cmd.join(' ')
end

directory build_dir

# some forms how to build the project once the cache is available
task b: [conan_toolchain] do
  nproc = `nproc`
  sh "cmake --build #{build_dir} -- -j #{Integer(nproc) - 1}"
  cp "#{build_dir}/compile_commands.json", '.'
end

# Task which updates the conan install whenever the conanfily.py changed
#
namespace :c do
  file conan_toolchain => ['conanfile.py'] do
    unless File.exist?(jigrake_info_json)
      puts "\ndevenv seems not to be set up correctly, please run "
      puts '$ rake gcc11:cache:debug'
      puts '# or '
      puts '$ rake gcc11:cache:release'
      puts
      exit
    end
    config = JSON.parse(File.read(jigrake_info_json))
    build_conan_install(config)
  end
end

# Metaprogrammed cache creation tasks.
#
# The creation of task is controlled by the existens of conan profile files
# located in conan.
#
# Each conan profile must support the form: <compiler>__<compiler_triplet>
#
# There is always a debug and a release cache initialization generated.
#
# rubocop:disable Metrics/BlockLength
Dir.glob('.conan/*') do |profile|
  basename = File.basename(profile)
  match = basename.match(/^(.+?)__/)
  if match
    compiler = match[1]
    namespace compiler.to_sym do
      namespace :cache do
        desc 'Initiale project in debug version'
        task debug: build_dir do
          config = {}
          config['type'] = 'Debug'
          config['compiler'] = compiler
          config['triplet'] = 'x86_64-pc-linux-elf'
          File.open(jigrake_info_json, 'w') do |fh|
            fh.write(JSON.dump(config))
          end

          build_conan_install(config)
          sh 'cmake --preset conan-debug'
          cp "#{build_dir}/compile_commands.json", '.' if File.exist?("#{build_dir}/compile_commands.json")
        end

        desc 'Initiale project in release version'
        task release: build_dir do
          config = {}
          config['type'] = 'Release'
          config['compiler'] = compiler
          config['triplet'] = 'x86_64-pc-linux-elf'
          File.open(jigrake_info_json, 'w') do |fh|
            fh.write(JSON.dump(config))
          end
          build_conan_install(config)
          sh 'cmake --preset conan-release'
          cp "#{build_dir}/compile_commands.json", '.' if File.exist?("#{build_dir}/compile_commands.json")
        end
      end
    end

  end
end
