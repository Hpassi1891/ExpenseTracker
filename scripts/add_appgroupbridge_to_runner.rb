#!/usr/bin/env ruby
# Adds ios/Runner/AppGroupBridge.swift to the Runner target's Sources build
# phase. Safe to re-run: it bails out if the file is already a member.
require 'xcodeproj'

project_path = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner_target

already_present = runner_target.source_build_phase.files_references.any? do |ref|
  ref.path == 'AppGroupBridge.swift'
end

if already_present
  puts 'AppGroupBridge.swift already in Runner Sources, nothing to do.'
  exit 0
end

runner_group = project.main_group.find_subpath('Runner', false)
raise 'Runner group not found' unless runner_group

file_ref = runner_group.new_reference('AppGroupBridge.swift')
runner_target.source_build_phase.add_file_reference(file_ref)

project.save

puts 'AppGroupBridge.swift added to Runner Sources build phase.'
