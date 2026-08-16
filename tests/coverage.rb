# frozen_string_literal: true

require "coverage"
require "fileutils"
require "json"

coverage_dir = ENV.fetch("MD2PDF_COVERAGE_DIR")
target = File.expand_path(ENV.fetch("MD2PDF_COVERAGE_TARGET"))

if $PROGRAM_NAME == __FILE__
  runs = Dir[File.join(coverage_dir, "*.json")].map { |path| JSON.parse(File.read(path)) }
  abort "no coverage data collected for #{target}" if runs.empty?

  merged = []
  runs.each do |lines|
    lines.each_with_index do |count, index|
      next if count.nil?

      merged[index] = (merged[index] || 0) + count
    end
  end

  executable = merged.count { |count| !count.nil? }
  covered = merged.count { |count| count&.positive? }
  percentage = covered.fdiv(executable) * 100
  printf "Line coverage: %d/%d (%.2f%%)\n", covered, executable, percentage
else
  Coverage.start(lines: true)
  at_exit do
    result = Coverage.result
    lines = result.dig(target, :lines)
    next unless lines

    FileUtils.mkdir_p(coverage_dir)
    File.write(File.join(coverage_dir, "#{Process.pid}.json"), JSON.generate(lines))
  end

  # Ruby compiles its main script before RUBYOPT hooks run, so load the
  # target after coverage starts and exit before the precompiled copy executes.
  if File.expand_path($PROGRAM_NAME) == target
    $PROGRAM_NAME = target
    load target
    exit
  end
end
