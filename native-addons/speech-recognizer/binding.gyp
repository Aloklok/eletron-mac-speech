{
  "targets": [
    {
      "target_name": "speech_recognizer",
      "sources": [
        "src/addon.mm",
        "src/SpeechRecognizer.swift"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "dependencies": [
        "<!(node -p \"require('node-addon-api').gyp\")"
      ],
      "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ],
      "xcode_settings": {
        # --- NEW: Architecture Settings ---
        # Specify the architectures to build for.
        "ARCHS": [
          "x86_64",
          "arm64"
        ],
        # Tell Xcode that these are the valid architectures.
        "VALID_ARCHS": [
          "x86_64",
          "arm64"
        ],
        # Ensure that both architectures are built, even in Release mode.
        "ONLY_ACTIVE_ARCH": "NO",
        
        # --- Existing Settings ---
        "MACOSX_DEPLOYMENT_TARGET": "10.15",
        "GCC_ENABLE_OBJC_EXCEPTIONS": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "c++17",
        "DEFINES_MODULE": "YES",
        "PRODUCT_MODULE_NAME": "speech_recognizer",
        "SWIFT_VERSION": "5.7",
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
