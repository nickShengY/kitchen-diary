require 'xcodeproj'
require 'fileutils'
require 'json'
root=File.expand_path('..',__dir__)
path=File.join(root,'KitchenDiary.xcodeproj')
p=Xcodeproj::Project.new(path)
p.root_object.attributes['LastUpgradeCheck']='2700'
p.build_configurations.each {|c| c.build_settings['SWIFT_VERSION']='5.0';c.build_settings['CLANG_ENABLE_MODULES']='YES'}
ios=p.new_target(:application,'KitchenDiary',:ios,'17.0')
watch=p.new_target(:application,'KitchenDiaryWatch',:watchos,'10.0')
tests=p.new_target(:unit_test_bundle,'KitchenDiaryTests',:ios,'17.0')
ui=p.new_target(:ui_test_bundle,'KitchenDiaryUITests',:ios,'17.0')
watchui=p.new_target(:ui_test_bundle,'KitchenDiaryWatchUITests',:watchos,'10.0')
group=p.main_group.new_group('Sources')
Dir.glob(File.join(root,'Shared/*.swift')).each {|file| ref=group.new_file(file);ios.add_file_references([ref]);watch.add_file_references([ref])}
Dir.glob(File.join(root,'KitchenDiary/*.swift')).each {|file| ios.add_file_references([group.new_file(file)])}
Dir.glob(File.join(root,'Watch/*.swift')).each {|file| watch.add_file_references([group.new_file(file)])}
Dir.glob(File.join(root,'Tests/*.swift')).each {|file| tests.add_file_references([group.new_file(file)])}
Dir.glob(File.join(root,'UITests/*.swift')).each {|file| ui.add_file_references([group.new_file(file)])}
Dir.glob(File.join(root,'WatchUITests/*.swift')).each {|file| watchui.add_file_references([group.new_file(file)])}
resources=p.main_group.new_group('Resources')
%w[catalog.json].each {|file|ref=resources.new_file(File.join(root,'Resources',file));ios.resources_build_phase.add_file_reference(ref);watch.resources_build_phase.add_file_reference(ref)}
ios.resources_build_phase.add_file_reference(resources.new_file(File.join(root,'Resources/Assets.xcassets')))
watch.resources_build_phase.add_file_reference(resources.new_file(File.join(root,'Resources/WatchAssets.xcassets')))
motion=resources.new_file(File.join(root,'Resources/Motion'));motion.last_known_file_type='folder';ios.resources_build_phase.add_file_reference(motion)
ios.resources_build_phase.add_file_reference(resources.new_file(File.join(root,'Resources/GoogleService-Info.plist')))
privacy=resources.new_file(File.join(root,'Resources/PrivacyInfo.xcprivacy'));ios.resources_build_phase.add_file_reference(privacy);watch.resources_build_phase.add_file_reference(privacy)
tests.resources_build_phase.add_file_reference(resources.new_file(File.join(root,'Resources/parity-fixtures.json')))
tests.resources_build_phase.add_file_reference(resources.new_file(File.join(root,'Resources/KitchenDiary.storekit')))
[[ios,'com.kitchendiary.app','Kitchen Diary'],[watch,'com.kitchendiary.app.watchkitapp','Kitchen Diary'],[tests,'com.kitchendiary.app.tests','KitchenDiaryTests'],[ui,'com.kitchendiary.app.uitests','KitchenDiaryUITests'],[watchui,'com.kitchendiary.app.watchkitapp.uitests','KitchenDiaryWatchUITests']].each do |target,bundle,name|
 target.build_configurations.each do |config|
  s=config.build_settings
  s['MARKETING_VERSION']='1.0.0';s['CURRENT_PROJECT_VERSION']='1';s['PRODUCT_BUNDLE_IDENTIFIER']=bundle;s['PRODUCT_NAME']=target.name;s['GENERATE_INFOPLIST_FILE']='YES';s['INFOPLIST_KEY_CFBundleDisplayName']=name;s['SWIFT_VERSION']='5.0';s['CODE_SIGN_STYLE']='Automatic';s['CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]']='NO';s['CODE_SIGNING_ALLOWED[sdk=watchsimulator*]']='NO';s['ENABLE_USER_SCRIPT_SANDBOXING']='YES';s['SWIFT_EMIT_LOC_STRINGS']='YES';s['SWIFT_STRICT_CONCURRENCY']='minimal'
  if target==ios
   s['CODE_SIGN_ENTITLEMENTS']='Resources/KitchenDiary.entitlements';s['TARGETED_DEVICE_FAMILY']='1,2';s['INFOPLIST_FILE']='Resources/Info.plist';s['INFOPLIST_KEY_UILaunchScreen_Generation']='YES';s['INFOPLIST_KEY_UIApplicationSceneManifest_Generation']='YES';s['INFOPLIST_KEY_UISupportedInterfaceOrientations']='UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight';s['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad']='UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight';s['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
  elsif target==watch
   s['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon';s['SDKROOT']='watchos';s['SUPPORTED_PLATFORMS']='watchos watchsimulator';s['TARGETED_DEVICE_FAMILY']='4';s['INFOPLIST_KEY_ITSAppUsesNonExemptEncryption']='NO';s['INFOPLIST_KEY_WKApplication']='YES';s['INFOPLIST_KEY_WKCompanionAppBundleIdentifier']='com.kitchendiary.app';s['INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp']='YES';s['SKIP_INSTALL']='YES'
  elsif target==tests
   s['TEST_HOST']='$(BUILT_PRODUCTS_DIR)/KitchenDiary.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/KitchenDiary';s['BUNDLE_LOADER']='$(TEST_HOST)';s['TARGETED_DEVICE_FAMILY']='1,2'
  elsif target==ui
   s['TEST_TARGET_NAME']='KitchenDiary';s['TARGETED_DEVICE_FAMILY']='1,2'
  elsif target==watchui
   s['TEST_TARGET_NAME']='KitchenDiaryWatch';s['SDKROOT']='watchos';s['SUPPORTED_PLATFORMS']='watchos watchsimulator';s['TARGETED_DEVICE_FAMILY']='4'
  end
 end
end
tests.add_dependency(ios);ui.add_dependency(ios);watchui.add_dependency(watch)
# Embed the independently runnable Watch app in the iPhone app.
ios.add_dependency(watch)
embed=ios.new_copy_files_build_phase('Embed Watch Content');embed.dst_subfolder_spec='16';embed.dst_path='$(CONTENTS_FOLDER_PATH)/Watch';embed.add_file_reference(watch.product_reference)
# Official SDKs; versions are locked in Package.resolved after the first resolution.
def package(p,url,version)
 ref=p.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference);ref.repositoryURL=url;ref.requirement={'kind'=>'upToNextMajorVersion','minimumVersion'=>version};p.root_object.package_references << ref;ref
end
firebase=package(p,'https://github.com/firebase/firebase-ios-sdk.git','12.0.0')
google=package(p,'https://github.com/google/GoogleSignIn-iOS.git','9.0.0')
{'FirebaseCore'=>firebase,'FirebaseAuth'=>firebase,'FirebaseFirestore'=>firebase,'GoogleSignIn'=>google}.each do |name,ref|
 dep=p.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency);dep.product_name=name;dep.package=ref;ios.package_product_dependencies << dep
 build=p.new(Xcodeproj::Project::Object::PBXBuildFile);build.product_ref=dep;ios.frameworks_build_phase.files << build
end
p.files.select {|f| f.path && f.path.end_with?('Foundation.framework')}.each {|f| f.path='System/Library/Frameworks/Foundation.framework';f.source_tree='SDKROOT'}
p.save
[[ios,[tests,ui]],[watch,[watchui]]].each do |target,test_targets|
 scheme=Xcodeproj::XCScheme.new;scheme.add_build_target(target);scheme.set_launch_target(target);test_targets.each {|t|scheme.add_test_target(t)}
 if target==ios
  scheme.launch_action.xml_element.add_element('StoreKitConfigurationFileReference',{'identifier'=>'../../Resources/KitchenDiary.storekit'})
  plan={'configurations'=>[{'id'=>'E689BEF4-C10D-4EAD-B55E-110010101010','name'=>'Native validation','options'=>{}}],'defaultOptions'=>{'storeKitConfigurationFile'=>{'identifier'=>'Resources/KitchenDiary.storekit'}},'testTargets'=>test_targets.map {|t| {'target'=>{'containerPath'=>'container:KitchenDiary.xcodeproj','identifier'=>t.uuid,'name'=>t.name}}},'version'=>1}
  File.write(File.join(root,'KitchenDiary.xctestplan'),JSON.pretty_generate(plan))
  scheme.test_action.xml_element.add_element('TestPlans').add_element('TestPlanReference',{'reference'=>'container:KitchenDiary.xctestplan','default'=>'YES'})
 end
 scheme.save_as(path,target.name,true)
end
puts path
