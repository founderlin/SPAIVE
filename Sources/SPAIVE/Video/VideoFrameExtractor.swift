#if canImport(UIKit)
import UIKit
import AVFoundation

/// 视频帧元数据
public struct FrameMetadata: Sendable {
    /// 帧索引（从 0 开始）
    public let index: Int
    /// 当前帧时间戳
    public let timestamp: CMTime
    /// 视频总时长
    public let duration: CMTime
}

/// 视频帧
public struct VideoFrame: Sendable {
    /// 帧图像
    public let image: UIImage
    /// 元数据
    public let metadata: FrameMetadata
}

/// 视频帧提取器
///
/// 负责从视频文件中按需提取图像帧。
/// 使用 actor 确保并发安全，并支持异步流式输出。
public actor VideoFrameExtractor {
    
    // MARK: - Errors
    
    public enum ExtractionError: Error, LocalizedError {
        case invalidVideoURL
        case assetLoadingFailed(Error)
        case frameGenerationFailed(CMTime, Error)
        case cancelled
        
        public var errorDescription: String? {
            switch self {
            case .invalidVideoURL:
                return "无效的视频 URL 或文件不存在。"
            case .assetLoadingFailed(let error):
                return "加载视频资源失败: \(error.localizedDescription)"
            case .frameGenerationFailed(let time, let error):
                return "无法生成 \(time.seconds) 秒处的帧: \(error.localizedDescription)"
            case .cancelled:
                return "帧提取任务已取消。"
            }
        }
    }
    
    // MARK: - Properties
    
    private let maxResolution: CGSize?
    
    // MARK: - Initialization
    
    /// 初始化帧提取器
    /// - Parameter maxResolution: 提取帧的最大分辨率（可选）。如果设置，生成的图片将被限制在此尺寸内。
    public init(maxResolution: CGSize? = nil) {
        self.maxResolution = maxResolution
    }
    
    // MARK: - Public API
    
    /// 提取视频帧流
    ///
    /// - Parameters:
    ///   - videoURL: 视频文件 URL
    ///   - fps: 目标帧率。如果为 nil，则尝试提取所有关键帧或按视频原始帧率提取（视实现策略而定，通常建议指定）。
    ///          如果指定了 FPS，将按固定时间间隔 `1.0 / fps` 抽帧。
    /// - Returns: 异步抛出流，生成 `VideoFrame`。
    public func extractFrames(
        from videoURL: URL,
        fps: Int? = nil
    ) -> AsyncThrowingStream<VideoFrame, Error> {
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // 1. 验证 URL
                    guard FileManager.default.fileExists(atPath: videoURL.path) else {
                        throw ExtractionError.invalidVideoURL
                    }
                    
                    // 2. 加载 Asset
                    let asset = AVAsset(url: videoURL)
                    let duration: CMTime
                    do {
                        duration = try await asset.load(.duration)
                    } catch {
                        throw ExtractionError.assetLoadingFailed(error)
                    }
                    
                    // 3. 配置生成器
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.requestedTimeToleranceBefore = .zero
                    generator.requestedTimeToleranceAfter = .zero
                    
                    if let maxRes = maxResolution {
                        generator.maximumSize = maxRes
                    }
                    
                    // 4. 计算时间点
                    let durationSeconds = CMTimeGetSeconds(duration)
                    let interval: Double
                    if let fps = fps, fps > 0 {
                        interval = 1.0 / Double(fps)
                    } else {
                        // 默认每秒 1 帧，或者尝试获取视频原始 FPS
                        // 为了简化，这里若未指定则默认为 1 FPS
                        interval = 1.0
                    }
                    
                    var currentTime: Double = 0
                    var frameIndex = 0
                    
                    // 5. 循环抽帧
                    while currentTime < durationSeconds {
                        // 检查取消
                        if Task.isCancelled {
                            throw ExtractionError.cancelled
                        }
                        
                        let time = CMTime(seconds: currentTime, preferredTimescale: 600)
                        
                        do {
                            // 注意：AVAssetImageGenerator.image(at:) 是同步阻塞的，
                            // 在 Swift Concurrency 中，对于大量帧可能需要注意。
                            // 但在 AsyncStream 的 Task 中运行是可以的。
                            // iOS 16+ 提供了 image(at:) async throws -> (CGImage, CMTime)
                            
                            let (cgImage, actualTime) = try await generator.image(at: time)
                            let image = UIImage(cgImage: cgImage)
                            
                            let metadata = FrameMetadata(
                                index: frameIndex,
                                timestamp: actualTime,
                                duration: duration
                            )
                            
                            let frame = VideoFrame(image: image, metadata: metadata)
                            continuation.yield(frame)
                            
                        } catch {
                            // 单帧失败是否终止整个流？
                            // 策略：记录错误并继续，或者抛出。这里选择抛出以便调用者知晓。
                            // 也可以选择跳过坏帧: print("Skipping bad frame at \(time)")
                            throw ExtractionError.frameGenerationFailed(time, error)
                        }
                        
                        currentTime += interval
                        frameIndex += 1
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            // 监听流的中断以取消任务
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
#endif
