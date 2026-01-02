import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import SPAIVE

final class SPAIVEVisualizerTests: XCTestCase {

    #if canImport(UIKit)
    func testAnnotation() {
        // 创建一个空白图片
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        
        // 创建检测对象
        let object = DetectedObject(
            label: "test",
            confidence: 0.9,
            boundingBox: CGRect(x: 50, y: 50, width: 100, height: 100)
        )
        
        // 初始化 Visualizer
        let visualizer = DetectionVisualizer(style: .default)
        
        // 执行标注
        let annotatedImage = visualizer.annotate(image: image, with: [object])
        
        // 简单验证：结果图片不应为 nil，且尺寸应一致
        XCTAssertNotNil(annotatedImage)
        XCTAssertEqual(annotatedImage.size, size)
        
        // 进阶验证（可选）：检查像素点颜色变化（例如边框处应有颜色）
        // 这里略过像素级验证，主要确保不崩溃且返回有效对象
    }
    
    func testStyleConfiguration() {
        let style = VisualizationStyle(
            lineWidth: 5.0,
            font: .systemFont(ofSize: 12),
            labelBackgroundAlpha: 0.5,
            labelTextColor: .black,
            colorScheme: .fixed(.red),
            showConfidence: false,
            showLabel: true
        )
        
        XCTAssertEqual(style.lineWidth, 5.0)
        XCTAssertFalse(style.showConfidence)
        
        if case .fixed(let color) = style.colorScheme {
            XCTAssertEqual(color, .red)
        } else {
            XCTFail("Color scheme mismatch")
        }
    }
    #endif
}
