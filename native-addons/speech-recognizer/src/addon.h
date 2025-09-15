// 文件：addon.h (最终版)
#pragma once
#include <napi.h>

class SpeechRecognizerWrapper : public Napi::ObjectWrap<SpeechRecognizerWrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports);
    SpeechRecognizerWrapper(const Napi::CallbackInfo& info);
    ~SpeechRecognizerWrapper();

    // 【已删除】移除 RequestAuthorization

private:
    void Start(const Napi::CallbackInfo& info);
    void Stop(const Napi::CallbackInfo& info);

    static Napi::FunctionReference constructor;
    Napi::Reference<Napi::Object> jsThisRef;
    id swiftRecognizer;
    Napi::ThreadSafeFunction onResultCallback;
    Napi::ThreadSafeFunction onErrorCallback;
};
