// 文件：native-addons/speech-recognizer/src/addon.mm
#import <Foundation/Foundation.h>
#include "addon.h"
#import "speech_recognizer-Swift.h"

// 定义在 .h 中声明的静态成员
Napi::FunctionReference SpeechRecognizerWrapper::constructor;


Napi::Object SpeechRecognizerWrapper::Init(Napi::Env env, Napi::Object exports) {
    Napi::HandleScope scope(env);
    Napi::Function func = DefineClass(env, "SpeechRecognizer", {
        InstanceMethod("start", &SpeechRecognizerWrapper::Start),
        InstanceMethod("stop", &SpeechRecognizerWrapper::Stop),
        // 【新增】将静态方法绑定到 JS 类的构造函数上
        StaticMethod("requestAuthorization", &SpeechRecognizerWrapper::RequestAuthorization)
    });
    // 【恢复】将构造函数保存到静态成员中
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

// addon.mm (RequestAuthorization 最终正确实现)

Napi::Value SpeechRecognizerWrapper::RequestAuthorization(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto deferred = Napi::Promise::Deferred::New(env);

    // 创建一个线程安全的回调，以便在 Swift 的异步回调中安全地操作 Promise
    auto tsfn = Napi::ThreadSafeFunction::New(
        env,
        Napi::Function::New(env, [](const Napi::CallbackInfo&){}), // 一个空 JS 函数
        "AuthorizationCallback",
        0,
        1,
        [deferred](Napi::Env) {
            // 这是一个 Finalizer，我们暂时不需要它
        });

    // 将线程安全函数指针和 deferred 对象打包，传递给 C 回调
    struct CallbackData {
        Napi::ThreadSafeFunction tsfn;
        Napi::Promise::Deferred deferred;
    };
    CallbackData* data = new CallbackData({tsfn, deferred});

    requestSpeechAuthorization([](bool authorized) {
        // 这个回调是从 Swift 调用的
        // 我们需要从一个全局地方获取 data 指针
        // 这太复杂了，让我们回到最初的 Objective-C 桥接！
    });

    return deferred.Promise();
}

// 模块初始化函数
Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return SpeechRecognizerWrapper::Init(env, exports);
}

NODE_API_MODULE(addon, InitAll)
