#!/usr/bin/env ruby
# Moves the "Embed App Extensions" copy-files phase to run before Flutter's
# "Thin Binary" script phase, which must run last. Appending it at the end
# (xcodeproj's default for new_copy_files_build_phase) creates a dependency
# cycle because Thin Binary implicitly touches the whole Runner.app bundle.
require 'xcodeproj'

project_path = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner_target

phases = runner_target.build_phases

embed_phase = phases.find { |p| p.respond_to?(:name) && p.name == 'Embed App Extensions' }
raise 'Embed App Extensions phase not found' unless embed_phase

thin_binary_index = phases.find_index do |p|
  p.respond_to?(:name) && p.name == 'Thin Binary'
end

if thin_binary_index.nil?
  puts 'No "Thin Binary" phase found; nothing to reorder.'
  exit 0
end

current_index = phases.find_index(embed_phase)

if current_index < thin_binary_index
  puts 'Embed App Extensions already runs before Thin Binary, nothing to do.'
  exit 0
end

phases.delete_at(current_index)
# thin_binary_index is still valid as an insertion point since we only
# removed an element that was after it.
phases.insert(thin_binary_index, embed_phase)

project.save

puts "Moved 'Embed App Extensions' to run before 'Thin Binary' (index #{thin_binary_index})."
