#!/bin/bash
# Script to create an Xcode project for Pill Reminder
# Run this once to generate the .xcodeproj directory

set -e

cd "$(dirname "$0")"

PROJECT_NAME="PillReminder"
PROJECT_PATH="${PROJECT_NAME}.xcodeproj"
PRODUCT_NAME="PillReminder"
BUNDLE_ID="com.example.pillreminder"
DEPLOYMENT_TARGET="16.0"

# Check if project already exists
if [ -d "$PROJECT_PATH" ]; then
    echo "⚠️  Project already exists at $PROJECT_PATH"
    echo "Delete it manually if you want to regenerate: rm -rf $PROJECT_PATH"
    exit 1
fi

echo "Creating Xcode project: $PROJECT_NAME"

# Create project directory structure
mkdir -p "$PROJECT_PATH/project.xcworkspace/xcshareddata/IDEWorkspaceChecks"
mkdir -p "$PROJECT_PATH/xcuserdata"

# Create project.pbxproj (minimal)
cat > "$PROJECT_PATH/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
/* Begin PBXBuildFile section */
		DA1C1A01283B8F3C00A1B8C1 /* PillReminderApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A00283B8F3C00A1B8C1 /* PillReminderApp.swift */; };
		DA1C1A02283B8F3C00A1B8C1 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A01283B8F3C00A1B8C1 /* ContentView.swift */; };
		DA1C1A03283B8F3C00A1B8C1 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = DA1C1A02283B8F3C00A1B8C1 /* Assets.xcassets */; };
		DA1C1A04283B8F3C00A1B8C1 /* Preview Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = DA1C1A03283B8F3C00A1B8C1 /* Preview Assets.xcassets */; };
		DA1C1A05283B8F3C00A1B8C1 /* ReminderManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A04283B8F3C00A1B8C1 /* ReminderManager.swift */; };
		DA1C1A06283B8F3C00A1B8C1 /* VoiceAckListener.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A05283B8F3C00A1B8C1 /* VoiceAckListener.swift */; };
		DA1C1A07283B8F3C00A1B8C1 /* SpeechSynthesizerService.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A06283B8F3C00A1B8C1 /* SpeechSynthesizerService.swift */; };
		DA1C1A08283B8F3C00A1B8C1 /* NewsWeatherService.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A07283B8F3C00A1B8C1 /* NewsWeatherService.swift */; };
		DA1C1A09283B8F3C00A1B8C1 /* Phrases.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A08283B8F3C00A1B8C1 /* Phrases.swift */; };
		DA1C1A0A283B8F3C00A1B8C1 /* PhraseCache.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A09283B8F3C00A1B8C1 /* PhraseCache.swift */; };
		DA1C1A0B283B8F3C00A1B8C1 /* ClaudeService.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A0A283B8F3C00A1B8C1 /* ClaudeService.swift */; };
		DA1C1A0C283B8F3C00A1B8C1 /* KeychainHelper.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A0B283B8F3C00A1B8C1 /* KeychainHelper.swift */; };
		DA1C1A0D283B8F3C00A1B8C1 /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = DA1C1A0C283B8F3C00A1B8C1 /* SettingsView.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		DA1C19FE283B8F3A00A1B8C1 /* PillReminder.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PillReminder.app; sourceTree = BUILT_PRODUCTS_DIR; };
		DA1C1A00283B8F3C00A1B8C1 /* PillReminderApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PillReminderApp.swift; sourceTree = "<group>"; };
		DA1C1A01283B8F3C00A1B8C1 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		DA1C1A02283B8F3C00A1B8C1 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		DA1C1A03283B8F3C00A1B8C1 /* Preview Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; };
		DA1C1A08283B8F3F00A1B8C1 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		DA1C1A04283B8F3C00A1B8C1 /* ReminderManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ReminderManager.swift; sourceTree = "<group>"; };
		DA1C1A05283B8F3C00A1B8C1 /* VoiceAckListener.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = VoiceAckListener.swift; sourceTree = "<group>"; };
		DA1C1A06283B8F3C00A1B8C1 /* SpeechSynthesizerService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SpeechSynthesizerService.swift; sourceTree = "<group>"; };
		DA1C1A07283B8F3C00A1B8C1 /* NewsWeatherService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NewsWeatherService.swift; sourceTree = "<group>"; };
		DA1C1A08283B8F3C00A1B8C1 /* Phrases.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Phrases.swift; sourceTree = "<group>"; };
		DA1C1A09283B8F3C00A1B8C1 /* PhraseCache.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PhraseCache.swift; sourceTree = "<group>"; };
		DA1C1A0A283B8F3C00A1B8C1 /* ClaudeService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ClaudeService.swift; sourceTree = "<group>"; };
		DA1C1A0B283B8F3C00A1B8C1 /* KeychainHelper.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = KeychainHelper.swift; sourceTree = "<group>"; };
		DA1C1A0C283B8F3C00A1B8C1 /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsView.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		DA1C19FB283B8F3A00A1B8C1 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		DA1C19F5283B8F3A00A1B8C1 = {
			isa = PBXGroup;
			children = (
				DA1C1A00283B8F3C00A1B8C1 /* PillReminderApp.swift */,
				DA1C1A01283B8F3C00A1B8C1 /* ContentView.swift */,
				DA1C1A04283B8F3C00A1B8C1 /* ReminderManager.swift */,
				DA1C1A05283B8F3C00A1B8C1 /* VoiceAckListener.swift */,
				DA1C1A06283B8F3C00A1B8C1 /* SpeechSynthesizerService.swift */,
				DA1C1A07283B8F3C00A1B8C1 /* NewsWeatherService.swift */,
				DA1C1A08283B8F3C00A1B8C1 /* Phrases.swift */,
				DA1C1A09283B8F3C00A1B8C1 /* PhraseCache.swift */,
				DA1C1A0A283B8F3C00A1B8C1 /* ClaudeService.swift */,
				DA1C1A0B283B8F3C00A1B8C1 /* KeychainHelper.swift */,
				DA1C1A0C283B8F3C00A1B8C1 /* SettingsView.swift */,
				DA1C1A02283B8F3C00A1B8C1 /* Assets.xcassets */,
				DA1C1A08283B8F3F00A1B8C1 /* Info.plist */,
				DA1C1A03283B8F3C00A1B8C1 /* Preview Assets.xcassets */,
			);
			sourceTree = SOURCE_ROOT;
		};
		DA1C19FF283B8F3A00A1B8C1 /* Products */ = {
			isa = PBXGroup;
			children = (
				DA1C19FE283B8F3A00A1B8C1 /* PillReminder.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		DA1C19FD283B8F3A00A1B8C1 /* PillReminder */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = DA1C1A0F283B8F3F00A1B8C1 /* Build configuration list for PBXNativeTarget "PillReminder" */;
			buildPhases = (
				DA1C19FA283B8F3A00A1B8C1 /* Sources */,
				DA1C19FB283B8F3A00A1B8C1 /* Frameworks */,
				DA1C19FC283B8F3A00A1B8C1 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = PillReminder;
			productName = PillReminder;
			productReference = DA1C19FE283B8F3A00A1B8C1 /* PillReminder.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		DA1C19F6283B8F3A00A1B8C1 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1400;
				LastUpgradeCheck = 1400;
				TargetAttributes = {
					DA1C19FD283B8F3A00A1B8C1 = {
						CreatedOnToolsVersion = 14.0;
					};
				};
			};
			buildConfigurationList = DA1C19F9283B8F3A00A1B8C1 /* Build configuration list for PBXProject "PillReminder" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
			);
			mainGroup = DA1C19F5283B8F3A00A1B8C1;
			productRefGroup = DA1C19FF283B8F3A00A1B8C1 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				DA1C19FD283B8F3A00A1B8C1 /* PillReminder */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		DA1C19FC283B8F3A00A1B8C1 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				DA1C1A04283B8F3C00A1B8C1 /* Preview Assets.xcassets in Resources */,
				DA1C1A03283B8F3C00A1B8C1 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		DA1C19FA283B8F3A00A1B8C1 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				DA1C1A01283B8F3C00A1B8C1 /* ContentView.swift in Sources */,
				DA1C1A02283B8F3C00A1B8C1 /* PillReminderApp.swift in Sources */,
				DA1C1A05283B8F3C00A1B8C1 /* ReminderManager.swift in Sources */,
				DA1C1A06283B8F3C00A1B8C1 /* VoiceAckListener.swift in Sources */,
				DA1C1A07283B8F3C00A1B8C1 /* SpeechSynthesizerService.swift in Sources */,
				DA1C1A08283B8F3C00A1B8C1 /* NewsWeatherService.swift in Sources */,
				DA1C1A09283B8F3C00A1B8C1 /* Phrases.swift in Sources */,
				DA1C1A0A283B8F3C00A1B8C1 /* PhraseCache.swift in Sources */,
				DA1C1A0B283B8F3C00A1B8C1 /* ClaudeService.swift in Sources */,
				DA1C1A0C283B8F3C00A1B8C1 /* KeychainHelper.swift in Sources */,
				DA1C1A0D283B8F3C00A1B8C1 /* SettingsView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		DA1C1A0D283B8F3F00A1B8C1 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_DIALECT = "gnu++17";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_SUSPICIOUS_MOVES = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		DA1C1A0E283B8F3F00A1B8C1 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_DIALECT = "gnu++17";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_SUSPICIOUS_MOVES = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZE_FOR_SIZE = YES;
				GCC_PREPROCESSOR_DEFINITIONS = "$(inherited)";
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		DA1C1A0F283B8F3F00A1B8C1 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_NSMicrophoneUsageDescription = "Used to listen for your spoken 'yes' when acknowledging a pill reminder.";
				INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "Used to recognize your spoken acknowledgment of pill reminders.";
				INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Used to fetch the local weather report after you acknowledge a reminder.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLandscapeLeft UIInterfaceOrientationLandscapeLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.pillreminder;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		DA1C1A10283B8F3F00A1B8C1 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_NSMicrophoneUsageDescription = "Used to listen for your spoken 'yes' when acknowledging a pill reminder.";
				INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "Used to recognize your spoken acknowledgment of pill reminders.";
				INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Used to fetch the local weather report after you acknowledge a reminder.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLandscapeLeft UIInterfaceOrientationLandscapeLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.pillreminder;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		DA1C19F9283B8F3A00A1B8C1 /* Build configuration list for PBXProject "PillReminder" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				DA1C1A0D283B8F3F00A1B8C1 /* Debug */,
				DA1C1A0E283B8F3F00A1B8C1 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		DA1C1A0F283B8F3F00A1B8C1 /* Build configuration list for PBXNativeTarget "PillReminder" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				DA1C1A0F283B8F3F00A1B8C1 /* Debug */,
				DA1C1A10283B8F3F00A1B8C1 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = DA1C19F6283B8F3A00A1B8C1 /* Project object */;
}
EOF

echo "✓ Created project.pbxproj"

# Create workspace
cat > "$PROJECT_PATH/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "group:">
   </FileRef>
</Workspace>
EOF

# Create workspace settings
cat > "$PROJECT_PATH/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEDidComputeMac32BitWarningV0</key>
	<true/>
</dict>
</plist>
EOF

echo "✓ Created workspace structure"
echo ""
echo "✅ Xcode project created successfully!"
echo ""
echo "Next steps:"
echo "1. Open the project: open $PROJECT_PATH"
echo "2. Set your Apple Developer team in Signing & Capabilities"
echo "3. Build and run on an iPhone (Cmd+R)"
