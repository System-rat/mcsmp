# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  # t.test_files = FileList['test/**/*_test.rb']
  t.test_files = FileList['test/mcsmp_test.rb']
end

Rake::TestTask.new(:optional_test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/mcsmp_optional_test.rb']
end

task default: :test

task all_tests: %i[test optional_test]
