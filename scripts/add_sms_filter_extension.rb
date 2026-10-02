#!/usr/bin/env ruby
# One-off script that wires the SmsFilterExtension App Extension target into
# Runner.xcodeproj. Safe to re-run: it bails out if the target already exists.
require 'xcodeproj'

project_path = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'SmsFilterExtension' }
  puts 'SmsFilterExtension target already exists, nothing to do.'
  exit 0
end

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner_target

bundle_id_base = 'com.expensetracker.expenseTracker'
deployment_target = '15.0'

# --- Group + file references -----------------------------------------------

ext_dir = File.join(__dir__, '..', 'ios', 'SmsFilterExtension')
ext_group = project.main_group.new_group('SmsFilterExtension', ext_dir)

swift_files = %w[MessageFilterExtension.swift SenderClassifier.swift AppGroupWriter.swift]
file_refs = swift_files.map { |f| ext_group.new_reference(f) }

info_plist_ref = ext_group.new_reference('Info.plist')
entitlements_ref = ext_group.new_reference('SmsFilterExtension.entitlements')

# --- Target ------------------------------------------------------------------

ext_target = project.new_target(
  :app_extension,
  'SmsFilterExtension',
  :ios,
  deployment_target,
  nil,
  :swift
)

file_refs.each { |ref| ext_target.source_build_phase.add_file_reference(ref) }

# Link IdentityLookup.framework (system framework)
frameworks_group = project.frameworks_group || project.main_group.new_group('Frameworks')
il_ref = frameworks_group.new_reference('System/Library/Frameworks/IdentityLookup.framework')
il_ref.source_tree = 'SDKROOT'
il_ref.name = 'IdentityLookup.framework'
ext_target.frameworks_build_phase.add_file_reference(il_ref)

ext_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id_base}.SmsFilterExtension"
  config.build_settings['PRODUCT_NAME'] = 'SmsFilterExtension'
  config.build_settings['INFOPLIST_FILE'] = 'SmsFilterExtension/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SmsFilterExtension/SmsFilterExtension.entitlements'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks',
  ]
end

# --- Embed extension into Runner --------------------------------------------

runner_target.add_dependency(ext_target)

embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13' # PlugIns
embed_phase.symbol_dst_subfolder_spec = :plug_ins
build_file = embed_phase.add_file_reference(ext_target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }

# --- Runner entitlements (App Group) ----------------------------------------

runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

project.save

puts 'SmsFilterExtension target added and embedded into Runner.'
