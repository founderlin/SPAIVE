#if canImport(UIKit)
import UIKit
import AVFoundation

/// 视频检测进度
public struct VideoDetectionProgress: Sendable {
    /// 当前处理的帧索引（从 0 开始）
    public let currentFrame: Int
    /// 预估总帧数
    public let totalFrames: Int
    /// 当前帧的检测结果
    public let result: DetectionResult
    /// 当前帧的元数据
    public let frameMetadata: FrameMetadata
    
    /// 进度百分比 [0.0, 1.0]
    public var percentage: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(currentFrame + 1) / Double(totalFrames)
    }
}

/// 视频检测服务
///
/// 整合了帧提取与目标检测，提供流式的视频分析能力。
/// 使用 actor 确保并发安全。
public actor VideoDetectionService {
    
    // MARK: - Properties
    
    private let detectionService: DetectionService
    private let frameExtractor: VideoFrameExtractor
    
    // MARK: - Initialization
    
    /// 初始化视频检测服务
    /// - Parameter configuration: 检测配置，将传递给底层的 `DetectionService`
    /// - Throws: 如果模型加载失败
    public init(configuration: DetectionConfiguration = .default) async throws {
        self.detectionService = try await DetectionService(configuration: configuration)
        // 视频抽帧时，限制最大分辨率以匹配输入或节省内存（可选）
        // 这里我们不限制最大分辨率，由 DetectionService 的 PreProcess 处理缩放
        self.frameExtractor = VideoFrameExtractor()
    }
    
    // MARK: - Public API
    
    /// 检测视频中的目标
    ///
    /// - Parameters:
    ///   - videoURL: 视频文件 URL
    ///   - fps: 处理帧率。默认 5 FPS。
    /// - Returns: 异步抛出流，生成 `VideoDetectionProgress`。
    public func detect(
        videoURL: URL,
        fps: Int = 5
    ) -> AsyncThrowingStream<VideoDetectionProgress, Error> {
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // 1. 估算总帧数（用于进度条）
                    let totalFrames = try await estimateTotalFrames(videoURL: videoURL, targetFPS: fps)
                    
                    // 2. 开始流式抽帧
                    let frameStream = await frameExtractor.extractFrames(from: videoURL, fps: fps)
                    
                    var processedCount = 0
                    
                    // 3. 逐帧检测
                    for try await videoFrame in frameStream {
                        // 检查取消
                        if Task.isCancelled {
                            throw DetectionError.cancelled
                        }
                        
                        // 执行检测
                        let detectionResult = try await detectionService.detect(image: videoFrame.image)
                        
                        // 修正时间戳：DetectionResult 默认时间戳可能是 0，我们可以填入视频时间戳
                        // 但 DetectionResult 是 let 属性，这里只能创建一个新的（如果需要）
                        // 或者直接在 VideoDetectionProgress 中提供 frameMetadata（已包含时间戳）
                        
                        let progress = VideoDetectionProgress(
                            currentFrame: processedCount,
                            totalFrames: totalFrames,
                            result: detectionResult,
                            frameMetadata: videoFrame.metadata
                        )
                        
                        continuation.yield(progress)
                        processedCount += 1
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Helpers
    
    /// 估算需要处理的总帧数
    private func estimateTotalFrames(videoURL: URL, targetFPS: Int) async throws -> Int {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds > 0 else { return 0 }
        
        // 逻辑需与 VideoFrameExtractor 一致：
        // 如果 targetFPS > 0，则间隔为 1.0 / targetFPS
        // 帧数 = ceil(duration / interval)
        // 实际上 VideoFrameExtractor 用的是 while currentTime < duration
        // 帧数约等于 duration * fps
        
        return Int(ceil(durationSeconds * Double(targetFPS)))
    }
}
#endif
