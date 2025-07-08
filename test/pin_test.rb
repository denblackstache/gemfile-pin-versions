# frozen_string_literal: true

require 'test_helper'
require_relative '../bin/gemfile-pin-versions'

class PinVersionsTest < Minitest::Test
  def setup
    @locked = {
      'rails' => Gem::Version.new('7.1.2'),
      'rake' => Gem::Version.new('13.0.6'),
      'nokogiri' => Gem::Version.new('1.15.4')
    }
  end

  def test_adds_strict_version_to_unversioned_gem
    lines = [ "gem 'rails'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'rails', '7.1.2'\n" ], result
  end

  def test_adds_pessimistic_version_constraints
    lines = [ "gem 'rails'\n" ]
    result = update_gemfile_lines(lines, @locked, true)
    assert_equal [ "gem 'rails', '~> 7.1', '>= 7.1.2'\n" ], result
  end

  def test_does_not_change_gems_with_existing_version
    lines = [ "gem 'rails', '7.1.2'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'rails', '7.1.2'\n" ], result
  end

  def test_does_not_change_non_gem_lines
    lines = [ "source 'https://rubygems.org'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "source 'https://rubygems.org'\n" ], result
  end

  def test_preserves_additional_gem_arguments
    lines = [ "gem 'rake', require: false\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'rake', '13.0.6', require: false\n" ], result
  end

  def test_double_quoted_gem_name
    lines = [ "gem \"nokogiri\"\n" ]
    # The current regex only matches single quotes, so this should remain unchanged
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem \"nokogiri\"\n" ], result
  end

  def test_gem_with_inline_comment
    lines = [ "gem 'rails' # core framework\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    # The comment is part of the remainder, so it will be treated as an argument
    assert_equal [ "gem 'rails', '7.1.2', # core framework\n" ], result
  end

  def test_gem_with_multiple_arguments
    lines = [ "gem 'nokogiri', platforms: :mri\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'nokogiri', '1.15.4', platforms: :mri\n" ], result
  end

  def test_gem_with_group_and_options
    lines = [ "gem 'rake', group: :test, require: false\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'rake', '13.0.6', group: :test, require: false\n" ], result
  end

  def test_gem_with_existing_version_constraint
    lines = [ "gem 'nokogiri', '>= 1.15.0'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'nokogiri', '>= 1.15.0'\n" ], result
  end

  def test_gem_not_in_lockfile
    lines = [ "gem 'not_in_lockfile'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "gem 'not_in_lockfile'\n" ], result
  end

  def test_indented_gem_line
    lines = [ "  gem 'rails'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "  gem 'rails', '7.1.2'\n" ], result
  end

  def test_empty_line_and_whitespace
    lines = [ "\n", "   \n", "gem 'rails'\n" ]
    result = update_gemfile_lines(lines, @locked, false)
    assert_equal [ "\n", "   \n", "gem 'rails', '7.1.2'\n" ], result
  end
end
