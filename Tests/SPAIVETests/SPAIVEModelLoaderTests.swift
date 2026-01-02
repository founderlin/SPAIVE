import XCTest
import CoreML
import Vision
@testable import SPAIVE

final class SPAIVEModelLoaderTests: XCTestCase {
    
    func testModelLoaderFailure() async {
        // 测试加载不存在的模型
        do {
            _ = try await ModelLoader.loadModel(named: "NonExistentModel")
            XCTFail("Should throw error for non-existent model")
        } catch let error as ModelLoader.LoadError {
            switch error {
            case .modelNotFound:
                // Expected
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // 注意：真实模型的加载测试依赖于 Bundle.module 中是否存在资源。
    // 在单元测试环境下，如果 .mlmodelc 没有正确被 Copy 到测试 bundle，可能会失败。
    // 这里我们主要测试错误路径，成功路径需要集成测试环境。
}
