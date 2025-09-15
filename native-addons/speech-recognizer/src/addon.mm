// 文件：addon.mm (最终正确版)
#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
#include "addon.h"
#import "speech_recognizer-Swift.h"

Napi::FunctionReference SpeechRecognizerWrapper::constructor;

Napi::Object SpeechRecognizerWrapper::Init(Napi::Env env, Napi::Object exports) {
    Napi::HandleScope scope(env);
    Napi::Function func = DefineClass(env, "SpeechRecognizer", {
        InstanceMethod("start", &SpeechRecognizerWrapper::Start),
        InstanceMethod("stop", &SpeechRecognizerWrapper::Stop)
    });
    constructor = Napi::Persistent(func);
    constructor.SuppressDestruct();
    exports.Set("SpeechRecognizer", func);
    return exports;
}

// 构造函数：初始化所有资源
SpeechRecognizerWrapper::SpeechRecognizerWrapper(const Napi::CallbackInfo& info) : Napi::ObjectWrap<SpeechRecognizerWrapper>(info) {
    Napi::Env env = info.Env();
    Napi::HandleScope scope(env);

    // 1. 创建对 JS `this` 对象的持久引用，防止被提前 GC
    this->jsThisRef = Napi::Persistent(info.This().As<Napi::Object>());

    // 2. 获取 JS 传入的选项
    Napi::Object options = info[0].As<Napi::Object>();
    std::string locale = options.Get("locale").As<Napi::String>();
    Napi::Function onResult = options.Get("onResult").As<Napi::Function>();
    Napi::Function onError = options.Get("onError").As<Napi::Function>();

    // 3. 创建线程安全函数 (TSFN)，这是从 Swift 回调 JS 的唯一通道
    this->onResultCallback = Napi::ThreadSafeFunction::New(env, onResult, "onResultCallback", 0, 1);
    this->onErrorCallback = Napi::ThreadSafeFunction::New(env, onError, "onErrorCallback", 0, 1);

    // 4. 创建 Swift 实例
    NSString* nsLocale = [NSString stringWithUTF8String:locale.c_str()];
    SpeechRecognizer* recognizer = [[SpeechRecognizer alloc] initWithLocaleIdentifier:nsLocale];
    this->swiftRecognizer = recognizer;
    
    // 5. 设置 Swift 实例的回调，让它们调用我们的 TSFN
    SpeechRecognizerWrapper* wrapper = this; // 捕获 this 指针
    
    [recognizer setOnResult:^(NSString* result) {
        std::string resultStr = [result UTF8String];
        // 使用 TSFN 的 BlockingCall 安全地调用 JS
        wrapper->onResultCallback.BlockingCall([resultStr](Napi::Env env, Napi::Function jsCallback) {
            jsCallback.Call({Napi::String::New(env, resultStr)});
        });
        // 【关键】在回调中减少引用计数
        wrapper->Unref();
    }];

    [recognizer setOnError:^(NSString* error) {
        std::string errorStr = [error UTF8String];
        wrapper->onErrorCallback.BlockingCall([errorStr](Napi::Env env, Napi::Function jsCallback) {
            jsCallback.Call({Napi::String::New(env, errorStr)});
        });
        // 【关键】在回调中减少引用计数
        wrapper->Unref();
    }];
}

// 析构函数：释放所有资源
SpeechRecognizerWrapper::~SpeechRecognizerWrapper() {
    this->onResultCallback.Release();
    this->onErrorCallback.Release();
    this->jsThisRef.Reset();
}

// Start 方法：只负责启动和增加引用计数
void SpeechRecognizerWrapper::Start(const Napi::CallbackInfo& info) {
    // 【关键】增加引用计数，防止在异步操作期间被 GC
    this->Ref();
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer start];
}

// Stop 方法：只负责调用 stop
void SpeechRecognizerWrapper::Stop(const Napi::CallbackInfo& info) {
    SpeechRecognizer* recognizer = (SpeechRecognizer*)this->swiftRecognizer;
    [recognizer stop];
    // 调用 stop 后，Swift 内部会触发 onError 或 onResult，
    // 在那里会调用 Unref()，所以这里不需要 Unref()。
}



Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return SpeechRecognizerWrapper::Init(env, exports);
}

NODE_API_MODULE(addon, InitAll)
