require 'test_helper'
require 'tempfile'

class PinVersionsSystemIntegrationTest < Minitest::Test
  def setup
    @gemfile_content = <<~GEMFILE
      source 'https://rubygems.org'
      gem 'rails'
      gem 'rake', require: false
      gem 'nokogiri', platforms: :mri
    GEMFILE

    @lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          nokogiri (1.15.4)
          rails (7.1.2)
          rake (13.0.6)

      PLATFORMS
        ruby

      DEPENDENCIES
        nokogiri
        rails
        rake

      BUNDLED WITH
         2.4.22
    LOCKFILE
  end

  def test_system_exec_pins_versions
    Dir.mktmpdir do |dir|
      gemfile = File.join(dir, 'Gemfile')
      lockfile = File.join(dir, 'Gemfile.lock')
      File.write(gemfile, @gemfile_content)
      File.write(lockfile, @lockfile_content)

      script_path = File.expand_path('../bin/gemfile-pin-versions.rb', __dir__)
      system("ruby #{script_path} > /dev/null 2>&1", chdir: dir)

      result = File.read(gemfile)
      assert_includes result, "gem 'rails', '7.1.2'"
      assert_includes result, "gem 'rake', '13.0.6', require: false"
      assert_includes result, "gem 'nokogiri', '1.15.4', platforms: :mri"
    end
  end

  def test_system_exec_with_pessimistic_flag
    Dir.mktmpdir do |dir|
      gemfile = File.join(dir, 'Gemfile')
      lockfile = File.join(dir, 'Gemfile.lock')
      File.write(gemfile, @gemfile_content)
      File.write(lockfile, @lockfile_content)

      script_path = File.expand_path('../bin/gemfile-pin-versions.rb', __dir__)
      system("ruby #{script_path} --pessimistic > /dev/null 2>&1", chdir: dir)

      result = File.read(gemfile)
      assert_includes result, "gem 'rails', '~> 7.1', '>= 7.1.2'"
      assert_includes result, "gem 'rake', '~> 13.0', '>= 13.0.6', require: false"
      assert_includes result, "gem 'nokogiri', '~> 1.15', '>= 1.15.4', platforms: :mri"
    end
  end
end