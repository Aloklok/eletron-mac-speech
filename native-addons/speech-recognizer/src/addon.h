// 文件：native-addons/speech-recognizer/src/addon.h (修正版)
#pragma once
#include <napi.h>

class SpeechRecognizerWrapper : public Napi::ObjectWrap<SpeechRecognizerWrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports);
    SpeechRecognizerWrapper(const Napi::CallbackInfo& info);
    ~SpeechRecognizerWrapper();

    // 【修正】将静态方法声明移到 public 区域
    static Napi::Value RequestAuthorization(const Napi::CallbackInfo& info);

private:
    // 实例方法保持 private
    void Start(const Napi::CallbackInfo& info);
    void Stop(const Napi::CallbackInfo& info);

    // Objective-C/Swift 对象的指针
    id swiftRecognizer;

    // 线程安全的 JS 回调函数
    Napi::ThreadSafeFunction onResultCallback;
    Napi::ThreadSafeFunction onErrorCallback;
}; // 确保这里只有一个结束花括号
