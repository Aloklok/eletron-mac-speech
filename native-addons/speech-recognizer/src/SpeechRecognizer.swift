import Speech
import AVFoundation

// @objc 标记是为了让这个类和它的方法能被 Objective-C 代码看到和调用
@objc(SpeechRecognizer)
public class SpeechRecognizer: NSObject {

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // 定义回调闭包，用于将结果传回给桥接代码
    @objc public var onResult: ((String) -> Void)?
    @objc public var onError: ((String) -> Void)?
    @objc public var onStart: (() -> Void)?

    @objc public init(localeIdentifier: String) {
        // 使用传入的语言标识符 (例如 "ja-JP") 初始化
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        super.init()
    }

    // 请求权限
    @objc public static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }

    // 开始识别
    @objc public func start() {
        // 确保在主线程执行UI和任务启动相关操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
                self.onError?("语音识别服务不可用")
                return
            }

            // 确保之前的任务已取消
            if self.recognitionTask != nil {
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }

            // 【macOS 修改点】: 移除了所有 AVAudioSession 相关代码。
            // 在 macOS 上，AVAudioEngine 会自动使用系统默认的输入设备，无需额外设置。

            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = self.recognitionRequest else {
                self.onError?("无法创建 SFSpeechAudioBufferRecognitionRequest 对象")
                return
            }
            // 根据您的代码，设置为 false，表示只需要最终识别结果
            request.shouldReportPartialResults = false 

            let inputNode = self.audioEngine.inputNode
            
            // 检查输入节点是否有可用的音频格式
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            guard recordingFormat.channelCount > 0 else {
                self.onError?("麦克风无可用输入。请检查系统权限和设备连接。")
                return
            }
            
            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                var isFinal = false

                if let result = result {
                    let bestString = result.bestTranscription.formattedString
                    self.onResult?(bestString) // 通过回调发送结果
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
                self.stop() // 启动失败时也清理资源
                return
            }
        }
    }

    // 停止识别
    @objc public func stop() {
        // 确保这些操作在主线程执行，避免线程问题
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.audioEngine.isRunning {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.finish() // 使用 finish() 确保最终结果被处理
            
            // 清理资源
            self.recognitionTask = nil
            self.recognitionRequest = nil
        }
    }
}