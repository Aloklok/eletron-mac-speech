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


// 文件：addon.mm (RequestAuthorization 最终正确版)

Napi::Value SpeechRecognizerWrapper::RequestAuthorization(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto deferred = Napi::Promise::Deferred::New(env);

    // 【关键修正 1】创建一个一次性的线程安全函数 (TSFN)
    // 这个 TSFN 的作用就是安全地调用 deferred.Resolve()
    Napi::ThreadSafeFunction tsfn = Napi::ThreadSafeFunction::New(
        env,
        Napi::Function::New(env, [](const Napi::CallbackInfo&){}), // 一个空的 JS 函数，因为我们不会直接调用它
        "AuthorizationCallback", // 资源名
        0,                       // Max queue size (0 = unlimited)
        1,                       // Initial thread count
        [deferred](Napi::Env) {
            // Finalizer: 当 TSFN 被释放时，如果 Promise 还没被 resolve，
            // 在这里 reject 它以避免挂起。
            // （为简单起见，我们暂时省略此逻辑）
        });

    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        // 这个回调块在未来的某个时刻在主线程上被调用
        
        // 【关键修正 2】将状态打包成一个 C++ 堆上的对象
        bool* authorizedStatus = new bool(status == SFSpeechRecognizerAuthorizationStatusAuthorized);

        // 【关键修正 3】使用 TSFN 的 BlockingCall 来安全地执行 JS 操作
        tsfn.BlockingCall([deferred, authorizedStatus](Napi::Env env, Napi::Function jsCallback) {
            // 这段代码现在在一个安全的作用域内执行
            deferred.Resolve(Napi::Boolean::New(env, *authorizedStatus));
            delete authorizedStatus; // 清理打包的数据
        });

        // 【关键修正 4】在完成调用后，释放 TSFN
        tsfn.Release();
    }];
    
    return deferred.Promise();
}

Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return SpeechRecognizerWrapper::Init(env, exports);
}

NODE_API_MODULE(addon, InitAll)
