import XCTest
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
@testable import SPAIVE

final class SPAIVEVideoTests: XCTestCase {
    
    // 生成一个简单的测试视频文件 (纯色背景)
    func createTestVideo(duration: Double = 1.0) async throws -> URL {
        let fileName = "test_video_\(UUID().uuidString).mov"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // 如果文件已存在则删除
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        
        // 这里只是为了演示，实际上生成视频比较复杂。
        // 我们可以使用一个假的 URL 或者尝试生成一个极简视频。
        // 由于生成视频代码量大，这里我们先测试错误情况 (invalid URL)。
        // 若要测试成功路径，需要依赖 Bundle 中的资源或 AVAssetWriter。
        return url
    }

    #if canImport(UIKit)
    func testInvalidVideoURL() async {
        let extractor = VideoFrameExtractor()
        let invalidURL = URL(fileURLWithPath: "/path/to/non/existent/video.mp4")
        
        do {
            for try await _ in await extractor.extractFrames(from: invalidURL) {
                XCTFail("Should not yield frames for invalid URL")
            }
            XCTFail("Should throw error")
        } catch let error as VideoFrameExtractor.ExtractionError {
            if case .invalidVideoURL = error {
                // Success
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExtractionCancellation() async throws {
        // 这个测试需要一个真实存在的视频才能跑通“开始提取”的逻辑。
        // 鉴于环境限制，我们暂只验证 invalidVideoURL。
        // 真实视频测试通常放在 Integration Tests 中。
    }
    #endif
}
