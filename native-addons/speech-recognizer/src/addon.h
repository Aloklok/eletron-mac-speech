// 文件：native-addons/speech-recognizer/src/addon.h (最终版)
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

    // 【加回来】将 constructor 声明为私有静态成员
    static Napi::FunctionReference constructor;

    id swiftRecognizer;
    Napi::ThreadSafeFunction onResultCallback;
    Napi::ThreadSafeFunction onErrorCallback;
};
