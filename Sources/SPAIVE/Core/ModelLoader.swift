import Foundation
import CoreML
import Vision

/// 模型加载器
///
/// 负责 CoreML 模型的查找、编译与加载。
/// 支持从 Bundle.module 中自动加载 .mlmodelc 或 .mlpackage。
public final class ModelLoader {
    
    // MARK: - Error Definitions
    
    public enum LoadError: Error, LocalizedError {
        case modelNotFound(String)
        case compilationFailed(Error)
        case invalidModelFormat
        case unsupportedModelVersion
        case modelLoadFailed(Error)
        
        public var errorDescription: String? {
            switch self {
            case .modelNotFound(let name):
                return "未找到模型文件: \(name)"
            case .compilationFailed(let error):
                return "模型编译失败: \(error.localizedDescription)"
            case .invalidModelFormat:
                return "无效的模型格式"
            case .unsupportedModelVersion:
                return "不支持的模型版本"
            case .modelLoadFailed(let error):
                return "模型加载失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Properties
    
    /// 模型缓存（避免重复加载）
    private static var loadedModels: [String: VNCoreMLModel] = [:]
    
    /// 线程安全锁
    private static let lock = NSLock()
    
    // MARK: - Public API
    
    /// 加载并验证模型
    ///
    /// 优先加载编译后的 `.mlmodelc` 目录；如果不存在，则尝试查找 `.mlpackage` 并进行即时编译。
    /// 加载成功后会将模型缓存，后续调用将直接返回缓存实例。
    ///
    /// - Parameter name: 模型名称（不含扩展名），例如 "yolo11n"
    /// - Returns: 已加载并准备就绪的 `VNCoreMLModel`
    /// - Throws: `LoadError`
    public static func loadModel(named name: String) async throws -> VNCoreMLModel {
        // 1. 检查缓存
        lock.lock()
        if let cachedModel = loadedModels[name] {
            lock.unlock()
            return cachedModel
        }
        lock.unlock()
        
        // 2. 查找模型 URL
        let modelURL = try findModelURL(named: name)
        
        // 3. 编译（如果需要）并加载
        let compiledURL: URL
        if modelURL.pathExtension == "mlpackage" {
            do {
                print("⚠️ 正在编译模型 \(name).mlpackage，这可能需要一些时间...")
                compiledURL = try await Task.detached {
                    try await compileModel(at: modelURL)
                }.value
            } catch {
                throw LoadError.compilationFailed(error)
            }
        } else {
            compiledURL = modelURL
        }
        
        // 4. 初始化 CoreML 模型
        let model: MLModel
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all // 优先使用 ANE/GPU
            model = try MLModel(contentsOf: compiledURL, configuration: config)
        } catch {
            throw LoadError.modelLoadFailed(error)
        }
        
        // 5. 验证模型规格 (可选)
        // try validateModel(model)
        
        // 6. 转换为 Vision 模型
        let visionModel: VNCoreMLModel
        do {
            visionModel = try VNCoreMLModel(for: model)
        } catch {
            throw LoadError.modelLoadFailed(error)
        }
        
        // 7. 写入缓存
        lock.lock()
        loadedModels[name] = visionModel
        lock.unlock()
        
        print("✅ 模型加载成功: \(name)")
        return visionModel
    }
    
    // MARK: - Private Helpers
    
    /// 查找模型文件 URL
    private static func findModelURL(named name: String) throws -> URL {
        // 优先查找 .mlmodelc (编译后的模型)
        if let url = Bundle.module.url(forResource: name, withExtension: "mlmodelc") {
            return url
        }
        
        // 其次查找 .mlpackage (源包)
        if let url = Bundle.module.url(forResource: name, withExtension: "mlpackage") {
            return url
        }
        
        throw LoadError.modelNotFound(name)
    }
    
    /// 编译模型
    private static func compileModel(at url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let compiledURL = try MLModel.compileModel(at: url)
                continuation.resume(returning: compiledURL)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 验证模型规格（预留）
    private static func validateModel(_ model: MLModel) throws {
        // 可以在这里检查输入名称是否为 "image"，输出是否包含 "coordinates" 等
        // 目前 YOLO 模型的输入输出名称可能因导出配置而异，暂时跳过强校验
    }
}
