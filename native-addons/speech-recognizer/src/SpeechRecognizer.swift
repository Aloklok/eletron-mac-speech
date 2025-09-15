// 文件：SpeechRecognizer.swift (最终版)
import Speech
import AVFoundation

// 【新增】创建一个专门用于处理静态/全局任务的类
@objc(SpeechRecognizerManager)
public class SpeechRecognizerManager: NSObject {
    // 【新增】将权限请求方法放在这个新类里
    @objc public static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
}

@objc(SpeechRecognizer)
public class SpeechRecognizer: NSObject {

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @objc public var onResult: ((String) -> Void)?
    @objc public var onError: ((String) -> Void)?
    @objc public var onStart: (() -> Void)?

    @objc public init(localeIdentifier: String) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        super.init()
    }

    // 【已删除】确保 requestAuthorization 方法已从这个类中删除

    @objc public func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
                self.onError?("语音识别服务不可用")
                return
            }
            if self.recognitionTask != nil {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = self.recognitionRequest else {
                self.onError?("无法创建 SFSpeechAudioBufferRecognitionRequest 对象")
                return
            }
            request.shouldReportPartialResults = false
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            guard recordingFormat.channelCount > 0 else {
                self.onError?("麦克风无可用输入。请检查系统权限和设备连接。")
                return
            }
            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                var isFinal = false
                if let result = result {
                    let bestString = result.bestTranscription.formattedString
                    self.onResult?(bestString)
                    isFinal = result.isFinal
                }
                if error != nil || isFinal {
                    self.stop()
                }
            }
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            self.audioEngine.prepare()
            do {
                try self.audioEngine.start()
                self.onStart?()
            } catch {
                self.onError?("音频引擎启动失败: \(error.localizedDescription)")
                self.stop()
            }
        }
    }

    @objc public func stop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.audioEngine.isRunning {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.finish()
            self.recognitionTask = nil
            self.recognitionRequest = nil
        }
    }
}
