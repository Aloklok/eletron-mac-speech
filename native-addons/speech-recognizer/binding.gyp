{
  "targets": [
    {
      "target_name": "speech_recognizer_swift",
      "type": "static_library",
      "sources": [ "src/SpeechRecognizer.swift" ],
      "xcode_settings": {
        "MACOSX_DEPLOYMENT_TARGET": "11.0",
        "SWIFT_VERSION": "5.0",
        "DEFINES_MODULE": "YES",
        "PRODUCT_NAME": "speech_recognizer",
        "PRODUCT_MODULE_NAME": "speech_recognizer",
        "SWIFT_OBJC_INTERFACE_HEADER_NAME": "speech_recognizer-Swift.h",
        "ARCHS": ["x86_64", "arm64"],
        "ONLY_ACTIVE_ARCH": "NO"
      }
    },
    {
      "target_name": "speech_recognizer",
      "sources": [ "src/addon.mm" ],
      "dependencies": [
        "speech_recognizer_swift",
        "<!(node -p \"require('node-addon-api').gyp\")"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "xcode_settings": {
        "MACOSX_DEPLOYMENT_TARGET": "11.0",
        "SWIFT_VERSION": "5.0",
        "CLANG_CXX_LANGUAGE_STANDARD": "c++17",
        "GCC_ENABLE_OBJC_EXCEPTIONS": "YES",
        "ARCHS": ["x86_64", "arm64"],
        "ONLY_ACTIVE_ARCH": "NO",
        "OTHER_CFLAGS": [
          "-fmodules",
          "-fcxx-modules",
          "-fobjc-arc"
        ],
        "OTHER_LDFLAGS": [
          "-framework", "Foundation",
          "-framework", "Speech",
          "-framework", "AVFoundation"
        ]
      }
    }
  ]
}
