import Foundation
import CoreGraphics

/// 非极大值抑制 (NMS) 处理器
public struct NMSProcessor {
    
    /// IoU 阈值
    ///
    /// 大于此阈值的重叠框将被抑制（剔除）。
    public let iouThreshold: Float
    
    /// 初始化 NMS 处理器
    /// - Parameter iouThreshold: IoU 阈值，默认为 0.45
    public init(iouThreshold: Float = 0.45) {
        self.iouThreshold = iouThreshold
    }
    
    /// 执行非极大值抑制
    ///
    /// - Parameter detections: 输入检测结果列表
    /// - Returns: 经过 NMS 过滤后的检测结果列表
    public func apply(_ detections: [DetectedObject]) -> [DetectedObject] {
        guard !detections.isEmpty else { return [] }
        
        // 按置信度排序（降序）
        let sorted = detections.sorted { $0.confidence > $1.confidence }
        
        var selected: [DetectedObject] = []
        var remaining = sorted
        
        while !remaining.isEmpty {
            // 选择置信度最高的
            let current = remaining.removeFirst()
            selected.append(current)
            
            // 移除与当前检测 IoU 过高的其他检测
            remaining = remaining.filter { detection in
                let iou = calculateIoU(current.boundingBox, detection.boundingBox)
                return iou < iouThreshold
            }
        }
        
        return selected
    }
    
    /// 计算两个边界框的 IoU (Intersection over Union)
    /// - Parameters:
    ///   - box1: 第一个边界框
    ///   - box2: 第二个边界框
    /// - Returns: IoU 值 [0, 1]
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        
        guard !intersection.isNull else { return 0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = box1.width * box1.height + box2.width * box2.height - intersectionArea
        
        guard unionArea > 0 else { return 0 }
        
        return Float(intersectionArea / unionArea)
    }
}
