import XCTest
import Vision
@testable import SPAIVE

final class SPAIVEPostProcessTests: XCTestCase {
    
    // MARK: - CoordinateConverter Tests
    
    func testCoordinateConversion() {
        // 假设图片尺寸 1000x1000
        let imageSize = CGSize(width: 1000, height: 1000)
        
        // Vision 坐标: 左下角原点，y 向上
        // 假设有一个框在左上角 (0, 900) - (100, 1000) [UIKit坐标]
        // 对应 Vision 归一化坐标: x=0, y=0.9, w=0.1, h=0.1
        // 因为 Vision y 是底部距离，顶部距离 0.9 意味着 y = 0.9
        // Wait, Vision origin is bottom-left.
        // UIKit top-left rect: x=0, y=0, w=100, h=100 (top 10%)
        // Vision normalized: x=0, y=0.9, w=0.1, h=0.1 (bottom is at 0.9, top is at 1.0)
        
        let visionRect = CGRect(x: 0, y: 0.9, width: 0.1, height: 0.1)
        let uikitRect = CoordinateConverter.visionToUIKit(normalizedBox: visionRect, imageSize: imageSize)
        
        XCTAssertEqual(uikitRect.origin.x, 0, accuracy: 0.001)
        XCTAssertEqual(uikitRect.origin.y, 0, accuracy: 0.001) // 1.0 - 0.9 - 0.1 = 0.0
        XCTAssertEqual(uikitRect.width, 100, accuracy: 0.001)
        XCTAssertEqual(uikitRect.height, 100, accuracy: 0.001)
        
        // 测试中心点
        // Vision: x=0.4, y=0.4, w=0.2, h=0.2 (Center: 0.5, 0.5)
        let centerRect = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
        let uikitCenterRect = CoordinateConverter.visionToUIKit(normalizedBox: centerRect, imageSize: imageSize)
        
        XCTAssertEqual(uikitCenterRect.origin.x, 400, accuracy: 0.001)
        // y = (1 - 0.4 - 0.2) * 1000 = 0.4 * 1000 = 400
        XCTAssertEqual(uikitCenterRect.origin.y, 400, accuracy: 0.001)
        XCTAssertEqual(uikitCenterRect.width, 200, accuracy: 0.001)
        XCTAssertEqual(uikitCenterRect.height, 200, accuracy: 0.001)
    }
    
    // MARK: - NMS Tests
    
    func testNMS() {
        let processor = NMSProcessor(iouThreshold: 0.5)
        
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let obj1 = DetectedObject(label: "test", confidence: 0.9, boundingBox: rect)
        // obj2 与 obj1 完全重叠 (IoU=1.0)，置信度较低 -> 应被移除
        let obj2 = DetectedObject(label: "test", confidence: 0.8, boundingBox: rect)
        // obj3 不重叠 -> 应保留
        let rect3 = CGRect(x: 200, y: 200, width: 100, height: 100)
        let obj3 = DetectedObject(label: "test", confidence: 0.7, boundingBox: rect3)
        
        let results = processor.apply([obj1, obj2, obj3])
        
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.confidence == 0.9 }))
        XCTAssertTrue(results.contains(where: { $0.confidence == 0.7 }))
        XCTAssertFalse(results.contains(where: { $0.confidence == 0.8 }))
    }
    
    // MARK: - DetectionPostProcessor Tests
    
    // 由于 VNRecognizedObjectObservation 难以直接初始化（它是 init() 是私有的或受限），
    // 我们可以测试 PostProcessor 的组件逻辑，或者 mock 行为。
    // 在这里我们主要信赖 NMSProcessor 和 CoordinateConverter 的单元测试。
    // 如果需要集成测试，通常需要构建真实的 Vision 请求，这在单元测试中较重。
    // 因此，上面的组件测试已经覆盖了核心逻辑。
}
