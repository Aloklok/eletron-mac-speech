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
      
      # 确保 defines 列表为空，不包含 NAPI_DISABLE_CPP_EXCEPTIONS
      "defines": [], 

      "xcode_settings": {
        "ARCHS": ["x86_64", "arm64"],
        "VALID_ARCHS": ["x86_64", "arm64"],
        "ONLY_ACTIVE_ARCH": "NO",
        "MACOSX_DEPLOYMENT_TARGET": "10.15",
        
        # --- 关键修正 ---
        # 明确告诉 Xcode 编译器，我们需要开启 C++ 异常支持
        "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
        # 同样，也开启 Objective-C 的异常支持
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
