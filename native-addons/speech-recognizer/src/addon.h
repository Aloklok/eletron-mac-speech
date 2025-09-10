// 文件：native-addons/speech-recognizer/src/addon.h
#pragma once
#include <napi.h>

class SpeechRecognizerWrapper : public Napi::ObjectWrap<SpeechRecognizerWrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports);
    SpeechRecognizerWrapper(const Napi::CallbackInfo& info);
    ~SpeechRecognizerWrapper();

private:
    static Napi::FunctionReference constructor;
    void Start(const Napi::CallbackInfo& info);
    void Stop(const Napi::CallbackInfo& info);

    // Objective-C/Swift 对象的指针
    id swiftRecognizer;

    // 线程安全的 JS 回调函数
    Napi::ThreadSafeFunction onResultCallback;
    Napi::ThreadSafeFunction onErrorCallback;
};