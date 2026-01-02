#if canImport(UIKit)
import UIKit
import CoreML
import Vision

/// 目标检测服务
///
/// 整合了模型加载、图像预处理、Core ML 推理以及后处理的完整流水线。
/// 使用 actor 模型确保并发安全。
public actor DetectionService {
    
    // MARK: - Properties
    
    private let model: VNCoreMLModel
    private let preprocessor: ImagePreprocessor
    private let postprocessor: DetectionPostProcessor
    private let configuration: DetectionConfiguration
    
    // MARK: - Initialization
    
    /// 初始化检测服务
    ///
    /// - Parameter configuration: 检测配置，包含模型名称、阈值等参数。
    /// - Throws: 如果模型加载失败，将抛出错误。
    public init(configuration: DetectionConfiguration = .default) async throws {
        self.configuration = configuration
        
        // 1. 加载模型 (这里假设模型名称固定为 yolo11n，或者将来可以放入配置中)
        self.model = try await ModelLoader.loadModel(named: "yolo11n")
        
        // 2. 初始化预处理器
        self.preprocessor = ImagePreprocessor(targetSize: configuration.inputSize)
        
        // 3. 初始化后处理器
        self.postprocessor = DetectionPostProcessor(configuration: configuration)
    }
    
    // MARK: - Detection
    
    /// 检测单张图像（异步）
    ///
    /// - Parameter image: 输入图像
    /// - Returns: 检测结果
    /// - Throws: `DetectionError`
    public func detect(image: UIImage) async throws -> DetectionResult {
        // 检查任务是否已取消
        try Task.checkCancellation()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. 预处理
        let pixelBuffer: CVPixelBuffer
        do {
            pixelBuffer = try preprocessor.process(image)
        } catch {
            throw DetectionError.preprocessingFailed(error)
        }
        
        // 再次检查取消
        try Task.checkCancellation()
        
        // 2. 推理
        let observations: [VNRecognizedObjectObservation]
        do {
            observations = try await performInference(on: pixelBuffer)
        } catch {
            throw DetectionError.inferenceFailed(error)
        }
        
        // 再次检查取消
        try Task.checkCancellation()
        
        // 3. 后处理
        let detectedObjects: [DetectedObject]
        do {
            detectedObjects = postprocessor.process(
                observations: observations,
                imageSize: image.size
            )
        } catch {
            // 虽然目前 postprocessor 不抛出错误，但为了未来扩展性保留 catch
            throw DetectionError.postprocessingFailed(error)
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return DetectionResult(
            objects: detectedObjects,
            imageSize: image.size,
            processingTime: processingTime
        )
    }
    
    /// 检测单张图像（同步/回调风格）
    ///
    /// 这是一个桥接方法，方便非 async 上下文调用。
    /// - Parameters:
    ///   - image: 输入图像
    ///   - completion: 完成回调
    public nonisolated func detect(
        image: UIImage,
        completion: @escaping (Result<DetectionResult, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await detect(image: image)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// 批量检测
    ///
    /// - Parameters:
    ///   - images: 输入图像数组
    ///   - progress: 进度回调 (0.0 - 1.0)
    /// - Returns: 检测结果数组
    public func detectBatch(
        images: [UIImage],
        progress: ((Double) -> Void)? = nil
    ) async throws -> [DetectionResult] {
        var results: [DetectionResult] = []
        let total = Double(images.count)
        
        for (index, image) in images.enumerated() {
            // 批量任务中，每处理一张图都检查取消状态
            try Task.checkCancellation()
            
            let result = try await detect(image: image)
            results.append(result)
            
            progress?(Double(index + 1) / total)
        }
        
        return results
    }
    
    // MARK: - Private Helpers
    
    /// 执行 Vision 推理
    private func performInference(on pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: observations)
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Error Handling

/// 检测过程中的错误
public enum DetectionError: Error, LocalizedError {
    case preprocessingFailed(Error)
    case inferenceFailed(Error)
    case postprocessingFailed(Error)
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .preprocessingFailed(let error):
            return "预处理失败: \(error.localizedDescription)"
        case .inferenceFailed(let error):
            return "模型推理失败: \(error.localizedDescription)"
        case .postprocessingFailed(let error):
            return "后处理失败: \(error.localizedDescription)"
        case .cancelled:
            return "任务已取消"
        }
    }
}
#endif
