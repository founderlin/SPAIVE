import XCTest
@testable import SPAIVE

final class SPAIVEMetricsTests: XCTestCase {

    func testDetectedObjectInitialization() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        let object = DetectedObject(label: "test", confidence: 0.9, boundingBox: rect)
        
        XCTAssertEqual(object.label, "test")
        XCTAssertEqual(object.confidence, 0.9)
        XCTAssertEqual(object.boundingBox, rect)
        
        // 测试计算属性
        XCTAssertEqual(object.area, 20000)
        XCTAssertEqual(object.center, CGPoint(x: 60, y: 120))
        XCTAssertEqual(object.aspectRatio, 0.5)
        XCTAssertEqual(object.formattedConfidence, "90.0%")
    }
    
    func testDetectedObjectCodable() throws {
        let object = DetectedObject(label: "car", confidence: 0.85, boundingBox: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DetectedObject.self, from: data)
        
        XCTAssertEqual(object.id, decoded.id)
        XCTAssertEqual(object.label, decoded.label)
        XCTAssertEqual(object.confidence, decoded.confidence)
        XCTAssertEqual(object.boundingBox, decoded.boundingBox)
    }
    
    func testDetectionResultFiltering() {
        let obj1 = DetectedObject(label: "person", confidence: 0.9, boundingBox: .zero)
        let obj2 = DetectedObject(label: "car", confidence: 0.5, boundingBox: .zero)
        let obj3 = DetectedObject(label: "person", confidence: 0.3, boundingBox: .zero)
        
        let result = DetectionResult(
            objects: [obj1, obj2, obj3],
            imageSize: CGSize(width: 100, height: 100),
            processingTime: 0.1
        )
        
        XCTAssertEqual(result.objectCount, 3)
        XCTAssertEqual(result.uniqueLabels, ["car", "person"])
        
        // 测试按标签过滤
        let persons = result.objects(withLabel: "person")
        XCTAssertEqual(persons.count, 2)
        
        // 测试按置信度过滤
        let highConfidence = result.objects(withConfidenceAbove: 0.8)
        XCTAssertEqual(highConfidence.count, 1)
        XCTAssertEqual(highConfidence.first?.label, "person")
        
        // 测试排序
        let sorted = result.sortedByConfidence(ascending: true)
        XCTAssertEqual(sorted.first?.confidence, 0.3)
        XCTAssertEqual(sorted.last?.confidence, 0.9)
    }
    
    func testCoordinateCalculations() {
        // IoU 测试
        let rect1 = CGRect(x: 0, y: 0, width: 10, height: 10) // 面积 100
        let rect2 = CGRect(x: 5, y: 0, width: 10, height: 10) // 面积 100，交集宽 5 高 10 = 50
        
        let obj1 = DetectedObject(label: "1", confidence: 1, boundingBox: rect1)
        let obj2 = DetectedObject(label: "2", confidence: 1, boundingBox: rect2)
        
        // IoU = 交集(50) / 并集(100 + 100 - 50) = 50 / 150 = 1/3
        let iou = obj1.iou(with: obj2)
        XCTAssertEqual(iou, 1.0/3.0, accuracy: 0.0001)
        
        // 无交集
        let rect3 = CGRect(x: 20, y: 20, width: 10, height: 10)
        let obj3 = DetectedObject(label: "3", confidence: 1, boundingBox: rect3)
        XCTAssertEqual(obj1.iou(with: obj3), 0)
    }
}
