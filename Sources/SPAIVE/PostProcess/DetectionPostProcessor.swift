import Foundation
import Vision
import CoreGraphics

/// 检测后处理器
///
/// 负责处理 Vision 框架的原始输出，包括：
/// 1. 置信度过滤
/// 2. 坐标转换 (Vision -> UIKit)
/// 3. 非极大值抑制 (NMS)
/// 4. 结果数量限制
public struct DetectionPostProcessor {
    
    private let nmsProcessor: NMSProcessor
    private let confidenceThreshold: Float
    private let maxDetections: Int
    
    /// 初始化检测后处理器
    /// - Parameter configuration: 检测配置
    public init(configuration: DetectionConfiguration) {
        self.confidenceThreshold = configuration.confidenceThreshold
        self.maxDetections = configuration.maxDetections
        self.nmsProcessor = NMSProcessor(iouThreshold: configuration.iouThreshold)
    }
    
    /// 处理 Vision 框架的原始输出
    ///
    /// - Parameters:
    ///   - observations: Vision 框架输出的识别对象列表
    ///   - imageSize: 原始图像尺寸（用于坐标转换）
    /// - Returns: 处理后的检测对象列表
    public func process(
        observations: [VNRecognizedObjectObservation],
        imageSize: CGSize
    ) -> [DetectedObject] {
        // 1. 预处理：过滤低置信度并进行坐标转换
        // 这一步先不做 NMS，先转成 DetectedObject 以便统一处理
        let rawDetections = observations.compactMap { observation -> DetectedObject? in
            guard observation.confidence >= confidenceThreshold else {
                return nil
            }
            
            let label = observation.labels.first?.identifier ?? "Unknown"
            
            // 坐标转换：Vision (归一化, 左下) -> UIKit (像素, 左上)
            let convertedBox = CoordinateConverter.visionToUIKit(
                normalizedBox: observation.boundingBox,
                imageSize: imageSize
            )
            
            return DetectedObject(
                label: label,
                confidence: observation.confidence,
                boundingBox: convertedBox
            )
        }
        
        // 2. 应用 NMS（非极大值抑制）
        // NMSProcessor 内部会处理按置信度排序和 IoU 过滤
        let nmsResults = nmsProcessor.apply(rawDetections)
        
        // 3. 限制最大检测数量
        // NMS 返回的结果通常已经是排序过的，这里直接取前 N 个
        let finalResults = Array(nmsResults.prefix(maxDetections))
        
        return finalResults
    }
}
