#if canImport(UIKit)
@_exported import CoreML
@_exported import Vision
import UIKit

// MARK: - Core Type Aliases

/// 检测配置（别名）
public typealias SPAIVEConfiguration = DetectionConfiguration
/// 检测结果（别名）
public typealias SPAIVEResult = DetectionResult
/// 检测对象（别名）
public typealias SPAIVEObject = DetectedObject

// MARK: - SPAIVE API

/// SPAIVE 统一入口
///
/// 提供了一组便捷的静态方法，用于图像和视频的目标检测以及结果可视化。
public enum SPAIVE {
    
    // MARK: - Image Detection
    
    /// 检测图像中的目标（异步）
    ///
    /// 创建一个新的检测服务实例并执行一次检测。
    /// 适用于单次、低频的检测任务。如果需要高频批量处理，建议直接实例化 `DetectionService` 并复用。
    ///
    /// - Parameters:
    ///   - image: 输入图像
    ///   - configuration: 检测配置。默认为 `.default`。
    /// - Returns: 检测结果
    /// - Throws: 如果模型加载失败或检测过程中发生错误。
    ///
    /// # 示例
    /// ```swift
    /// let image = UIImage(named: "test.jpg")!
    /// let result = try await SPAIVE.detect(image: image)
    /// print("Found \(result.objects.count) objects")
    /// ```
    public static func detect(
        image: UIImage,
        configuration: SPAIVEConfiguration = .default
    ) async throws -> SPAIVEResult {
        let service = try await DetectionService(configuration: configuration)
        return try await service.detect(image: image)
    }
    
    // MARK: - Video Detection
    
    /// 检测视频中的目标（流式）
    ///
    /// 创建一个新的视频检测服务实例并开始流式处理。
    /// 支持异步迭代返回每一帧的检测结果和进度。
    ///
    /// - Parameters:
    ///   - videoURL: 视频文件 URL
    ///   - fps: 处理帧率。默认 5 FPS。
    ///   - configuration: 检测配置。默认为 `.default`。
    /// - Returns: 异步抛出流，生成 `VideoDetectionProgress`。
    ///
    /// # 示例
    /// ```swift
    /// for try await progress in SPAIVE.detect(videoURL: url, fps: 10) {
    ///     print("Frame \(progress.currentFrame): \(progress.result.objects.count) objects")
    /// }
    /// ```
    public static func detect(
        videoURL: URL,
        fps: Int = 5,
        configuration: SPAIVEConfiguration = .default
    ) async throws -> AsyncThrowingStream<VideoDetectionProgress, Error> {
        let service = try await VideoDetectionService(configuration: configuration)
        return await service.detect(videoURL: videoURL, fps: fps)
    }
    
    // MARK: - Visualization
    
    /// 可视化检测结果
    ///
    /// 将检测到的目标框和标签绘制在原始图像上。
    ///
    /// - Parameters:
    ///   - image: 原始图像
    ///   - objects: 检测对象列表
    ///   - style: 可视化样式配置。默认为 `.default`。
    /// - Returns: 带标注的合成图像。
    ///
    /// # 示例
    /// ```swift
    /// let annotatedImage = SPAIVE.annotate(image: originalImage, with: result.objects)
    /// imageView.image = annotatedImage
    /// ```
    public static func annotate(
        image: UIImage,
        with objects: [SPAIVEObject],
        style: VisualizationStyle = .default
    ) -> UIImage {
        DetectionVisualizer(style: style).annotate(image: image, with: objects)
    }
}
#endif
