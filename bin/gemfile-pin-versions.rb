require 'bundler'
require 'optparse'

GEMFILE = 'Gemfile'
LOCKFILE = 'Gemfile.lock'

def parse_options
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: pin_versions.rb [--pessimistic]'
    opts.on('--pessimistic', 'Use pessimistic constraint (~>) instead of strict version') do
      options[:pessimistic] = true
    end
  end.parse!
  options
end

def locked_versions
  lockfile = Bundler::LockfileParser.new(Bundler.read_file(LOCKFILE))
  lockfile.specs.to_h { |spec| [ spec.name, spec.version ] }
rescue Errno::ENOENT
  abort "Lockfile not found"
end

def format_version_constraints(version, pessimistic)
  if pessimistic
    major, minor, patch = version.segments[0], version.segments[1], version.segments[2] || 0
    pessimistic_constraint = "~> #{major}.#{minor}"
    minimum_patch_constraint = ">= #{major}.#{minor}.#{patch}"
    [ "'#{pessimistic_constraint}'", "'#{minimum_patch_constraint}'" ]
  else
    [ "'#{version}'" ]
  end
end

def update_gemfile_lines(lines, locked, pessimistic)
  lines.map do |line|
    if line =~ /^(\s*)gem\s+'([^']+)'(.*)$/
      indent, gem_name, remainder = Regexp.last_match.captures
      remainder.strip!
      version_present = remainder.match?(/['"][><=~^]*\s*\d/)
      if !version_present && locked[gem_name]
        args = remainder.split(/,(?=(?:[^']|'[^']*')*$)/).map(&:strip).reject(&:empty?)
        version_constraints = format_version_constraints(locked[gem_name], pessimistic)
        args = version_constraints + args
        "#{indent}gem '#{gem_name}', #{args.join(', ')}\n"
      else
        line
      end
    else
      line
    end
  end
end

def main
  options = parse_options
  unless File.exist?(GEMFILE) && File.exist?(LOCKFILE)
    abort "#{GEMFILE} or #{LOCKFILE} not found."
  end
  original_lines = File.readlines(GEMFILE)
  locked = locked_versions
  updated_lines = update_gemfile_lines(original_lines, locked, options[:pessimistic])
  File.write(GEMFILE, updated_lines.join)
  puts "Gemfile updated with #{options[:pessimistic] ? '~>' : 'strict'} versions for unversioned gems."
end

main if __FILE__ == $0