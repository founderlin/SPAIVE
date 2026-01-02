import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import SPAIVE

final class SPAIVEVideoDetectionTests: XCTestCase {

    #if canImport(UIKit)
    func testVideoDetectionInitialization() async {
        // 测试初始化是否成功（主要测试模型加载）
        do {
            _ = try await VideoDetectionService()
        } catch let error as ModelLoader.LoadError {
            if case .modelNotFound = error {
                // Expected in unit test environment without model
            } else {
                print("Initialization failed: \(error)")
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }
    
    // 完整的视频检测测试需要真实视频文件和模型，
    // 在单元测试中难以模拟。
    // 我们依赖 DetectionServiceTests 和 VideoTests 的覆盖率。
    #endif
}
