import Foundation
import CoreGraphics

/// 检测结果模型
///
/// 包含单次推理的所有检测对象及相关元数据（图片尺寸、处理时间等）。
public struct DetectionResult: Codable, Identifiable, Sendable {
    
    /// 唯一标识符
    public let id: UUID
    
    /// 检测到的对象列表
    public let objects: [DetectedObject]
    
    /// 原始图片尺寸
    public let imageSize: CGSize
    
    /// 处理耗时（秒）
    public let processingTime: TimeInterval
    
    /// 视频帧时间戳（秒），若是静态图片则通常为 0
    public let timestamp: TimeInterval
    
    // MARK: - Initialization
    
    /// 初始化检测结果
    ///
    /// - Parameters:
    ///   - id: 唯一标识符
    ///   - objects: 检测对象列表
    ///   - imageSize: 图片尺寸
    ///   - processingTime: 处理耗时
    ///   - timestamp: 时间戳
    public init(
        id: UUID = UUID(),
        objects: [DetectedObject] = [],
        imageSize: CGSize,
        processingTime: TimeInterval,
        timestamp: TimeInterval = 0
    ) {
        self.id = id
        self.objects = objects
        self.imageSize = imageSize
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Computed Properties

public extension DetectionResult {
    
    /// 检测到的对象数量
    var objectCount: Int {
        objects.count
    }
    
    /// 是否包含任何对象
    var hasObjects: Bool {
        !objects.isEmpty
    }
    
    /// 唯一的标签列表（已排序）
    var uniqueLabels: [String] {
        Array(Set(objects.map { $0.label })).sorted()
    }
    
    /// 格式化的处理时间 (例如 "15 ms" 或 "1.20 s")
    var formattedProcessingTime: String {
        if processingTime < 1 {
            return String(format: "%.0f ms", processingTime * 1000)
        } else {
            return String(format: "%.2f s", processingTime)
        }
    }
}

// MARK: - Filtering Methods

public extension DetectionResult {
    
    /// 过滤特定标签的对象
    /// - Parameter label: 目标标签
    /// - Returns: 仅包含该标签的检测对象数组
    func objects(withLabel label: String) -> [DetectedObject] {
        objects.filter { $0.label == label }
    }
    
    /// 过滤置信度高于阈值的对象
    /// - Parameter threshold: 置信度阈值 [0.0, 1.0]
    /// - Returns: 置信度 >= 阈值的对象数组
    func objects(withConfidenceAbove threshold: Float) -> [DetectedObject] {
        objects.filter { $0.confidence >= threshold }
    }
    
    /// 按置信度排序
    /// - Parameter ascending: 是否升序，默认 false（降序）
    /// - Returns: 排序后的对象数组
    func sortedByConfidence(ascending: Bool = false) -> [DetectedObject] {
        objects.sorted { ascending ? $0.confidence < $1.confidence : $0.confidence > $1.confidence }
    }
}

// MARK: - Equatable & Hashable

extension DetectionResult: Equatable, Hashable {
    public static func == (lhs: DetectionResult, rhs: DetectionResult) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
