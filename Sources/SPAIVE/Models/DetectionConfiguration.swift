import Foundation
import CoreGraphics

/// 目标检测配置
///
/// 定义了模型推理和后处理阶段的参数，包括置信度过滤、NMS 阈值等。
/// 遵循 `Codable` 和 `Sendable` 协议，便于序列化和并发传递。
public struct DetectionConfiguration: Codable, Sendable {
    
    /// 置信度阈值，范围 [0.0, 1.0]
    ///
    /// 只有置信度分数（Confidence Score）大于或等于此值的检测结果才会被保留。
    /// 值越高，检测越严格（误报少，漏报多）；值越低，检测越宽松（误报多，漏报少）。
    public let confidenceThreshold: Float
    
    /// IoU (Intersection over Union) 阈值，范围 [0.0, 1.0]
    ///
    /// 用于非极大值抑制（NMS）阶段。当两个检测框的 IoU 大于此阈值时，
    /// 将被视为对同一目标的重复检测，置信度较低的框将被移除。
    /// 值越小，去重越严格（容易把邻近物体当成同一个）；值越大，去重越宽松。
    public let iouThreshold: Float
    
    /// 最大检测数量
    ///
    /// 单张图片中允许返回的最大目标数量。NMS 后会根据置信度排序，保留前 N 个结果。
    public let maxDetections: Int
    
    /// 模型输入尺寸
    ///
    /// 图片在送入模型前将被缩放（通常为拉伸或填充）至此尺寸。
    /// 需与模型训练时的输入尺寸一致（如 YOLOv8/v11 通常为 640x640）。
    public let inputSize: CGSize
    
    // MARK: - Initialization
    
    /// 初始化检测配置
    ///
    /// - Parameters:
    ///   - confidenceThreshold: 置信度阈值，自动限制在 0.0-1.0 之间。默认 0.5。
    ///   - iouThreshold: IoU 阈值，自动限制在 0.0-1.0 之间。默认 0.45。
    ///   - maxDetections: 最大检测数，必须大于 0。默认 100。
    ///   - inputSize: 输入尺寸。默认 640x640。
    public init(
        confidenceThreshold: Float = 0.5,
        iouThreshold: Float = 0.45,
        maxDetections: Int = 100,
        inputSize: CGSize = CGSize(width: 640, height: 640)
    ) {
        // 参数验证与清洗
        self.confidenceThreshold = max(0.0, min(1.0, confidenceThreshold))
        self.iouThreshold = max(0.0, min(1.0, iouThreshold))
        self.maxDetections = max(1, maxDetections)
        self.inputSize = inputSize
    }
    
    // MARK: - Presets
    
    /// 默认配置（平衡模式）
    ///
    /// 推荐用于大多数通用场景。
    /// - confidenceThreshold: 0.5
    /// - iouThreshold: 0.45
    public static let `default` = DetectionConfiguration(
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        maxDetections: 100
    )
    
    /// 严格模式
    ///
    /// 适用于对误报零容忍的场景。
    /// - confidenceThreshold: 0.75 (高置信度)
    /// - iouThreshold: 0.3 (更激进的去重)
    public static let strict = DetectionConfiguration(
        confidenceThreshold: 0.75,
        iouThreshold: 0.3,
        maxDetections: 50
    )
    
    /// 宽松模式
    ///
    /// 适用于需要尽可能多召回目标的场景（允许一定误报）。
    /// - confidenceThreshold: 0.25 (低置信度)
    /// - iouThreshold: 0.6 (更宽松的去重)
    public static let relaxed = DetectionConfiguration(
        confidenceThreshold: 0.25,
        iouThreshold: 0.6,
        maxDetections: 200
    )
}
