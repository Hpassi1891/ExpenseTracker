#!/usr/bin/env ruby
# Reverts the SmsFilterExtension target + App Groups wiring added by
# add_sms_filter_extension.rb / add_appgroupbridge_to_runner.rb.
#
# App Groups is unavailable under free (non-paid) Apple ID provisioning,
# which blocks sideloading entirely. This script detaches the extension
# target and entitlements from the Xcode project so the app builds and
# signs again on a free account. The Swift source files under
# ios/SmsFilterExtension/ and ios/Runner/AppGroupBridge.swift are left on
# disk (just unreferenced) for reuse once a paid account is available.
require 'xcodeproj'

project_path = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner_target

ext_target = project.targets.find { |t| t.name == 'SmsFilterExtension' }

if ext_target
  # Remove the dependency Runner has on the extension target.
  runner_target.dependencies.select { |d| d.target == ext_target }.each(&:remove_from_project)

  # Remove the "Embed App Extensions" copy files phase.
  embed_phase = runner_target.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Embed App Extensions' }
  embed_phase&.remove_from_project

  # Remove AppGroupBridge.swift from Runner's Sources build phase (and its
  # file reference) - it's dead code without the extension to feed it.
  bridge_build_file = runner_target.source_build_phase.files_references.find { |r| r.path == 'AppGroupBridge.swift' }
  if bridge_build_file
    runner_target.source_build_phase.remove_file_reference(bridge_build_file)
  end

  ext_target.remove_from_project
  puts 'Removed SmsFilterExtension target and its Runner wiring.'
else
  puts 'SmsFilterExtension target not present, skipping target removal.'
end

# Remove the SmsFilterExtension group (file references) from the project
# navigator - the files stay on disk, just no longer part of the project.
ext_group = project.main_group.find_subpath('SmsFilterExtension', false)
ext_group&.remove_from_project

# Clear Runner's entitlements build setting - Runner.entitlements only ever
# contained the now-unusable App Groups entry.
runner_target.build_configurations.each do |config|
  config.build_settings.delete('CODE_SIGN_ENTITLEMENTS')
end

project.save

puts 'Project reverted to a free-account-compatible state.'
