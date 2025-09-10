// 文件：native-addons/speech-recognizer/binding.gyp
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