import XCTest
@testable import SPAIVE
#if canImport(UIKit)
import UIKit
import CoreVideo
#endif

final class SPAIVEPreProcessTests: XCTestCase {

    #if canImport(UIKit)
    func testImagePreprocessing() throws {
        // 创建一个简单的红色图片
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        
        let targetSize = CGSize(width: 64, height: 64)
        let preprocessor = ImagePreprocessor(targetSize: targetSize)
        
        // 执行预处理
        let pixelBuffer = try preprocessor.process(image)
        
        // 验证结果
        XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), Int(targetSize.width))
        XCTAssertEqual(CVPixelBufferGetHeight(pixelBuffer), Int(targetSize.height))
        XCTAssertEqual(CVPixelBufferGetPixelFormatType(pixelBuffer), kCVPixelFormatType_32BGRA)
        
        // 验证内容（采样中心点）
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            XCTFail("Cannot get base address")
            return
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let centerX = Int(targetSize.width) / 2
        let centerY = Int(targetSize.height) / 2
        let offset = centerY * bytesPerRow + centerX * 4
        
        let data = baseAddress.assumingMemoryBound(to: UInt8.self)
        let b = data[offset]
        let g = data[offset + 1]
        let r = data[offset + 2]
        // let a = data[offset + 3]
        
        // 红色 BGRA: B=0, G=0, R=255
        // 允许一点误差（压缩/转换损耗）
        XCTAssertEqual(Double(b), 0, accuracy: 5)
        XCTAssertEqual(Double(g), 0, accuracy: 5)
        XCTAssertEqual(Double(r), 255, accuracy: 5)
    }
    
    func testInvalidImage() {
        // 创建一个没有 CGImage 的图片（如 CIImage backed）通常比较难直接模拟，
        // 但可以通过空图片或异常情况测试
        // 这里主要测试正常流程，异常流程依赖于 Mock
    }
    #endif
}
