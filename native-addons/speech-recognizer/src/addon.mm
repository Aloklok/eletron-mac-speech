#import <Foundation/Foundation.h>
#include "addon.h"
// Use the explicit header import, which is more reliable with multiple targets
#import "speech_recognizer-Swift.h"
Napi::FunctionReference SpeechRecognizerWrapper::constructor;

Napi::Object SpeechRecognizerWrapper::Init(Napi::Env env, Napi::Object exports) {
    Napi::HandleScope scope(env);
    Napi::Function func = DefineClass(env, "SpeechRecognizer", {
        InstanceMethod("start", &SpeechRecognizerWrapper::Start),
        InstanceMethod("stop", &SpeechRecognizerWrapper::Stop),
    });
    constructor = Napi::Persistent(func);
    constructor.SuppressDestruct();
    exports.Set("SpeechRecognizer", func);
    return exports;
}

SpeechRecognizerWrapper::SpeechRecognizerWrapper(const Napi::CallbackInfo& info) : Napi::ObjectWrap<SpeechRecognizerWrapper>(info) {
    Napi::Env env = info.Env();
    Napi::HandleScope scope(env);

    Napi::Object options = info[0].As<Napi::Object>();
    std::string locale = options.Get("locale").As<Napi::String>();
    Napi::Function onResult = options.Get("onResult").As<Napi::Function>();
    Napi::Function onError = options.Get("onError").As<Napi::Function>();

    NSString* nsLocale = [NSString stringWithUTF8String:locale.c_str()];
    SpeechRecognizer* recognizer = [[SpeechRecognizer alloc] initWithLocaleIdentifier:nsLocale];
    this->swiftRecognizer = recognizer;

    this->onResultCallback = Napi::ThreadSafeFunction::New(env, onResult, "onResultCallback", 0, 1);
    this->onErrorCallback = Napi::ThreadSafeFunction::New(env, onError, "onErrorCallback", 0, 1);
    
    // 创建一个 this 指针的副本，以便在 block 中安全地使用
    SpeechRecognizerWrapper* wrapper = this;

    [recognizer setOnResult:^(NSString* result) {
        std::string resultStr = [result UTF8String];
        wrapper->onResultCallback.BlockingCall([resultStr](Napi::Env env, Napi::Function jsCallback) {
            jsCallback.Call({Napi::String::New(env, resultStr)});
        });
    }];

    [recognizer setOnError:^(NSString* error) {
        std::string errorStr = [error UTF8String];
        wrapper->onErrorCallback.BlockingCall([errorStr](Napi::Env env, Napi::Function jsCallback) {
            jsCallback.Call({Napi::String::New(env, errorStr)});
        });
    }];
}

SpeechRecognizerWrapper::~SpeechRecognizerWrapper() {
    // 析构函数，当 JS 对象被垃圾回收时调用，安全释放资源
    this->onResultCallback.Release();
    this->onErrorCallback.Release();
    // this->swiftRecognizer 会被 ARC 自动释放
}

void SpeechRecognizerWrapper::Start(const Napi::CallbackInfo& info) {
    // 将 id 类型转回具体的 Swift 桥接类型来调用方法
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer start];
}

void SpeechRecognizerWrapper::Stop(const Napi::CallbackInfo& info) {
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer stop];
}

// 模块初始化函数
Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return SpeechRecognizerWrapper::Init(env, exports);
}

NODE_API_MODULE(addon, InitAll)
