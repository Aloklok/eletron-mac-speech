// 文件：SpeechRecognizer.swift (为你提供的版本添加日志)
import Speech
import AVFoundation
import os.log // 导入统一日志系统

// 【新增】创建一个日志记录器，方便在 Console.app 中过滤
let speechLog = OSLog(subsystem: "com.yourcompany.learning-app", category: "SpeechRecognizer")

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
        os_log(">>> Swift: init(localeIdentifier: %{public}@) called.", log: speechLog, type: .debug, localeIdentifier)
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        super.init()
    }

    @objc public func start() {
        os_log(">>> Swift: start() called.", log: speechLog, type: .debug)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                os_log(">>> Swift: self is nil in start() dispatch block.", log: speechLog, type: .error)
                return
            }

            os_log(">>> Swift: Checking recognizer availability...", log: speechLog, type: .debug)
            guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
                let errorMsg = "语音识别服务不可用"
                os_log(">>> Swift: ERROR: %{public}@", log: speechLog, type: .error, errorMsg)
                self.onError?(errorMsg)
                return
            }

            if self.recognitionTask != nil {
                os_log(">>> Swift: Previous task found, cancelling.", log: speechLog, type: .debug)
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
            }

            os_log(">>> Swift: Creating SFSpeechAudioBufferRecognitionRequest.", log: speechLog, type: .debug)
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let request = self.recognitionRequest else {
                let errorMsg = "无法创建 SFSpeechAudioBufferRecognitionRequest 对象"
                os_log(">>> Swift: ERROR: %{public}@", log: speechLog, type: .error, errorMsg)
                self.onError?(errorMsg)
                return
            }
            request.shouldReportPartialResults = false

            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            os_log(">>> Swift: Checking recording format.", log: speechLog, type: .debug)
            guard recordingFormat.channelCount > 0 else {
                let errorMsg = "麦克风无可用输入。请检查系统权限和设备连接。"
                os_log(">>> Swift: ERROR: %{public}@", log: speechLog, type: .error, errorMsg)
                self.onError?(errorMsg)
                return
            }
            
            os_log(">>> Swift: Creating recognition task.", log: speechLog, type: .debug)
            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                os_log(">>> Swift: Recognition task callback fired.", log: speechLog, type: .debug)
                var isFinal = false
                if let result = result {
                    let bestString = result.bestTranscription.formattedString
                    os_log(">>> Swift: Got result: %{public}@", log: speechLog, type: .info, bestString)
                    self.onResult?(bestString)
                    isFinal = result.isFinal
                }
                if error != nil {
                    os_log(">>> Swift: Task reported an error: %{public}@", log: speechLog, type: .error, error!.localizedDescription)
                }
                if isFinal {
                    os_log(">>> Swift: Task is final.", log: speechLog, type: .debug)
                }
                if error != nil || isFinal {
                    self.stop()
                }
            }
            
            os_log(">>> Swift: Installing tap on input node.", log: speechLog, type: .debug)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }

            os_log(">>> Swift: Preparing audio engine.", log: speechLog, type: .debug)
            self.audioEngine.prepare()
            
            do {
                os_log(">>> Swift: Starting audio engine...", log: speechLog, type: .debug)
                try self.audioEngine.start()
                os_log(">>> Swift: Audio engine started successfully.", log: speechLog, type: .info)
                self.onStart?()
            } catch {
                let errorMsg = "音频引擎启动失败: \(error.localizedDescription)"
                os_log(">>> Swift: CRITICAL: %{public}@", log: speechLog, type: .fault, errorMsg)
                self.onError?(errorMsg)
                self.stop()
            }
        }
    }

    @objc public func stop() {
        os_log(">>> Swift: stop() called.", log: speechLog, type: .debug)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                os_log(">>> Swift: self is nil in stop() dispatch block.", log: speechLog, type: .error)
                return
            }
            if self.audioEngine.isRunning {
                os_log(">>> Swift: Audio engine is running, stopping it.", log: speechLog, type: .debug)
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                os_log(">>> Swift: Audio engine stopped and tap removed.", log: speechLog, type: .debug)
            }
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.finish()
            self.recognitionTask = nil
            self.recognitionRequest = nil
            os_log(">>> Swift: Resources cleaned up.", log: speechLog, type: .debug)
        }
    }
}
