// 文件：addon.h (最终正确版)
#pragma once
#include <napi.h>

class SpeechRecognizerWrapper : public Napi::ObjectWrap<SpeechRecognizerWrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports);
    SpeechRecognizerWrapper(const Napi::CallbackInfo& info);
    ~SpeechRecognizerWrapper();

    static Napi::Value RequestAuthorization(const Napi::CallbackInfo& info);

private:
    void Start(const Napi::CallbackInfo& info);
    void Stop(const Napi::CallbackInfo& info);

    static Napi::FunctionReference constructor;

    // 【关键】确保这个引用存在，用于管理 JS 对象的生命周期
    Napi::Reference<Napi::Object> jsThisRef;

    id swiftRecognizer;
    Napi::ThreadSafeFunction onResultCallback;
    Napi::ThreadSafeFunction onErrorCallback;
};
