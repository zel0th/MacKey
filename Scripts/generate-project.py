#!/usr/bin/env python3
"""Generate a dependency-free native Xcode project; paths are deterministic."""
from pathlib import Path
import hashlib
import json
import plistlib

root = Path(__file__).resolve().parent.parent
project = root / 'MacKey.xcodeproj'
project.mkdir(exist_ok=True)
def uid(value): return hashlib.sha1(value.encode()).hexdigest()[:24].upper()
def q(value): return json.dumps(str(value), ensure_ascii=False)
objects = []
def obj(name, body):
    ident = uid(name)
    objects.append(f'\t\t{ident} = {{ {body} }};')
    return ident
files = sorted((root / 'Sources').rglob('*.swift'))
refs = []
builds = []
for path in files:
    rel = path.relative_to(root).as_posix()
    ref = obj('file:' + rel, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(rel)}; sourceTree = SOURCE_ROOT;')
    refs.append(ref)
    builds.append(obj('build:' + rel, f'isa = PBXBuildFile; fileRef = {ref};'))
product = obj('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MacKey.app; sourceTree = BUILT_PRODUCTS_DIR;')
icon = obj('icon', 'isa = PBXFileReference; lastKnownFileType = image.icns; path = Design/AppIcon.icns; sourceTree = SOURCE_ROOT;')
iconbuild = obj('iconbuild', f'isa = PBXBuildFile; fileRef = {icon};')
plist = obj('plist', 'isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = SOURCE_ROOT;')
entitlements = obj('entitlements', 'isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MacKey.entitlements; sourceTree = SOURCE_ROOT;')
products = obj('products', f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
sources = obj('sourcegroup', f'isa = PBXGroup; children = ({",".join(refs)},); name = Sources; sourceTree = "<group>";')
main = obj('main', f'isa = PBXGroup; children = ({sources},{icon},{plist},{entitlements},{products},); sourceTree = "<group>";')
sourcephase = obj('sourcephase', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(builds)},); runOnlyForDeploymentPostprocessing = 0;')
frameworkphase = obj('frameworkphase', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
resourcephase = obj('resourcephase', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({iconbuild},); runOnlyForDeploymentPostprocessing = 0;')
projectconfigs = []
appconfigs = []
for config in ['Debug','Release']:
    common = 'CLANG_ENABLE_MODULES = YES; MACOSX_DEPLOYMENT_TARGET = 14.0; SDKROOT = macosx; SWIFT_VERSION = 6.0; ENABLE_TESTABILITY = YES;'
    common += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG_INFORMATION_FORMAT = dwarf; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;' if config == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
    projectconfigs.append(obj('projectconfig:'+config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ {common} }};'))
    settings = 'PRODUCT_NAME = MacKey; PRODUCT_BUNDLE_IDENTIFIER = dev.mackey.MacKey; INFOPLIST_FILE = Info.plist; GENERATE_INFOPLIST_FILE = NO; CODE_SIGN_STYLE = Automatic; CODE_SIGN_IDENTITY = "-"; CODE_SIGN_ENTITLEMENTS = MacKey.entitlements; ENABLE_APP_SANDBOX = YES; ENABLE_HARDENED_RUNTIME = YES; COMBINE_HIDPI_IMAGES = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks"; CURRENT_PROJECT_VERSION = 2; MARKETING_VERSION = 1.0.1;'
    appconfigs.append(obj('appconfig:'+config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ {settings} }};'))
projectlist = obj('projectlist', f'isa = XCConfigurationList; buildConfigurations = ({",".join(projectconfigs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
applist = obj('applist', f'isa = XCConfigurationList; buildConfigurations = ({",".join(appconfigs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target = obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {applist}; buildPhases = ({sourcephase},{frameworkphase},{resourcephase},); buildRules = (); dependencies = (); name = MacKey; productName = MacKey; productReference = {product}; productType = "com.apple.product-type.application";')
testfile = obj('testfile', 'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tests/MacKeyCoreTests/TrainingTests.swift; sourceTree = SOURCE_ROOT;')
testbuild = obj('testbuild', f'isa = PBXBuildFile; fileRef = {testfile};')
testproduct = obj('testproduct', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MacKeyTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
testphase = obj('testphase', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({testbuild},); runOnlyForDeploymentPostprocessing = 0;')
testframework = obj('testframework', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
testconfigs = []
for config in ['Debug', 'Release']:
    settings = 'PRODUCT_NAME = MacKeyTests; PRODUCT_BUNDLE_IDENTIFIER = dev.mackey.MacKeyTests; GENERATE_INFOPLIST_FILE = YES; CODE_SIGN_STYLE = Automatic; CODE_SIGN_IDENTITY = "-"; BUNDLE_LOADER = "$(TEST_HOST)"; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/MacKey.app/Contents/MacOS/MacKey"; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @loader_path/../Frameworks @executable_path/../Frameworks";'
    testconfigs.append(obj('testconfig:'+config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ {settings} }};'))
testconfiglist = obj('testconfiglist', f'isa = XCConfigurationList; buildConfigurations = ({",".join(testconfigs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
proxy = obj('testproxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = MacKey;')
dependency = obj('testdependency', f'isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};')
testtarget = obj('testtarget', f'isa = PBXNativeTarget; buildConfigurationList = {testconfiglist}; buildPhases = ({testphase},{testframework},); buildRules = (); dependencies = ({dependency},); name = MacKeyTests; productName = MacKeyTests; productReference = {testproduct}; productType = "com.apple.product-type.bundle.unit-test";')
objects = [line.replace(f'children = ({sources},', f'children = ({testfile},{sources},').replace(f'children = ({product},);', f'children = ({product},{testproduct},);') for line in objects]
proj = obj('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {projectlist}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ru; hasScannedForEncodings = 0; knownRegions = (ru,en,Base,); mainGroup = {main}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},{testtarget},);')
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n'+'\n'.join(objects)+'\n\t};\n\trootObject = '+proj+';\n}\n')
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacKey.app" BlueprintName="MacKey" ReferencedContainer="container:MacKey.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{testtarget}" BuildableName="MacKeyTests.xctest" BlueprintName="MacKeyTests" ReferencedContainer="container:MacKey.xcodeproj"/></TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacKey.app" BlueprintName="MacKey" ReferencedContainer="container:MacKey.xcodeproj"/></BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacKey.app" BlueprintName="MacKey" ReferencedContainer="container:MacKey.xcodeproj"/></BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
schemedir = project / 'xcshareddata/xcschemes'
schemedir.mkdir(parents=True, exist_ok=True)
(schemedir / 'MacKey.xcscheme').write_text(scheme)
info = {'CFBundleName':'MacKey','CFBundleDisplayName':'MacKey','CFBundleIdentifier':'dev.mackey.MacKey','CFBundleExecutable':'MacKey','CFBundlePackageType':'APPL','CFBundleShortVersionString':'1.0.1','CFBundleVersion':'2','LSMinimumSystemVersion':'14.0','NSHighResolutionCapable':True,'NSPrincipalClass':'NSApplication','CFBundleIconFile':'AppIcon','LSApplicationCategoryType':'public.app-category.education','NSHumanReadableCopyright':'MacKey · 2026'}
(root / 'Info.plist').write_bytes(plistlib.dumps(info))
(root / 'MacKey.entitlements').write_bytes(plistlib.dumps({'com.apple.security.app-sandbox': True, 'com.apple.security.files.user-selected.read-write': True}))
print(f'Generated project with {len(files)} Swift files')
