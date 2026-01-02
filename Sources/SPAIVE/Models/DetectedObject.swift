import Foundation
import CoreGraphics

/// 检测到的单个目标
///
/// 表示在图像中检测到的单个物体，包含类别、置信度和空间位置信息。
///
/// ## 坐标系约定
/// - **坐标原点**: 图像左上角 (0, 0)。
/// - **单位**: 像素 (Pixel)。
/// - **方向**: X 轴向右增长，Y 轴向下增长。
/// - **边界框**: 使用标准的 `CGRect`，即 `(x, y, width, height)`。
public struct DetectedObject: Codable, Identifiable, Equatable, Sendable {
    
    /// 唯一标识符
    public let id: UUID
    
    /// 类别标签
    ///
    /// 模型的分类输出，例如 "person", "car", "dog"。
    public let label: String
    
    /// 置信度，范围 [0.0, 1.0]
    ///
    /// 表示模型对该检测结果的确定程度。
    public let confidence: Float
    
    /// 边界框
    ///
    /// 目标在原始图像中的位置和大小。
    /// - Note: 使用 UIKit 坐标系（原点左上角）。
    public let boundingBox: CGRect
    
    // MARK: - Initialization
    
    /// 初始化检测对象
    ///
    /// - Parameters:
    ///   - id: 唯一标识符，默认为新 UUID
    ///   - label: 类别标签
    ///   - confidence: 置信度
    ///   - boundingBox: 边界框
    public init(
        id: UUID = UUID(),
        label: String,
        confidence: Float,
        boundingBox: CGRect
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

// MARK: - Computed Properties

public extension DetectedObject {
    
    /// 边界框的中心点
    var center: CGPoint {
        CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }
    
    /// 边界框的面积
    var area: CGFloat {
        boundingBox.width * boundingBox.height
    }
    
    /// 宽高比 (width / height)
    ///
    /// 如果高度为 0，则返回 0。
    var aspectRatio: CGFloat {
        guard boundingBox.height > 0 else { return 0 }
        return boundingBox.width / boundingBox.height
    }
    
    /// 格式化的置信度字符串 (例如 "95.5%")
    var formattedConfidence: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

// MARK: - Helpers

public extension DetectedObject {
    /// 计算与另一个对象的 IoU (Intersection over Union)
    func iou(with other: DetectedObject) -> Float {
        let intersection = boundingBox.intersection(other.boundingBox)
        guard !intersection.isNull else { return 0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = area + other.area - intersectionArea
        
        guard unionArea > 0 else { return 0 }
        return Float(intersectionArea / unionArea)
    }
}
