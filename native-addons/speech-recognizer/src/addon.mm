// 文件：addon.mm (最终版)
#import <Foundation/Foundation.h>
#import <Speech/Speech.h> // 【新增】直接导入原生 Speech 框架
#include "addon.h"
#import "speech_recognizer-Swift.h"

Napi::FunctionReference SpeechRecognizerWrapper::constructor;

Napi::Object SpeechRecognizerWrapper::Init(Napi::Env env, Napi::Object exports) {
    Napi::HandleScope scope(env);
    Napi::Function func = DefineClass(env, "SpeechRecognizer", {
        InstanceMethod("start", &SpeechRecognizerWrapper::Start),
        InstanceMethod("stop", &SpeechRecognizerWrapper::Stop),
        StaticMethod("requestAuthorization", &SpeechRecognizerWrapper::RequestAuthorization)
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
    // 【修正】修复了 this.onErrorCallback 的语法错误
    this->onErrorCallback = Napi::ThreadSafeFunction::New(env, onError, "onErrorCallback", 0, 1);
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
    this->onResultCallback.Release();
    this->onErrorCallback.Release();
}

void SpeechRecognizerWrapper::Start(const Napi::CallbackInfo& info) {
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer start];
}

void SpeechRecognizerWrapper::Stop(const Napi::CallbackInfo& info) {
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer stop];
}

// 【关键修正】完全在 Objective-C++ 中实现权限请求
Napi::Value SpeechRecognizerWrapper::RequestAuthorization(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto deferred = Napi::Promise::Deferred::New(env);
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        // 确保在主线程上操作 Promise
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
                deferred.Resolve(Napi::Boolean::New(env, true));
            } else {
                deferred.Resolve(Napi::Boolean::New(env, false));
            }
        });
    }];
    
    return deferred.Promise();
}

Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return SpeechRecognizerWrapper::Init(env, exports);
}

NODE_API_MODULE(addon, InitAll)
