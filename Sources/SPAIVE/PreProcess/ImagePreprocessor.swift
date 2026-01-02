#if canImport(UIKit)
import UIKit
import CoreVideo

/// 图像预处理器
///
/// 负责将 `UIImage` 转换为模型推理所需的 `CVPixelBuffer`。
/// 支持自定义目标尺寸和像素格式。
public struct ImagePreprocessor {
    
    // MARK: - Properties
    
    /// 目标尺寸
    ///
    /// 图像将被缩放（通常为拉伸）至此尺寸。
    public let targetSize: CGSize
    
    /// 像素格式
    ///
    /// 例如 `kCVPixelFormatType_32BGRA`。
    public let pixelFormat: OSType
    
    // MARK: - Initialization
    
    /// 初始化预处理器
    ///
    /// - Parameters:
    ///   - targetSize: 目标尺寸，默认为 640x640。
    ///   - pixelFormat: 像素格式，默认为 BGRA。
    public init(
        targetSize: CGSize = CGSize(width: 640, height: 640),
        pixelFormat: OSType = kCVPixelFormatType_32BGRA
    ) {
        self.targetSize = targetSize
        self.pixelFormat = pixelFormat
    }
    
    // MARK: - Processing
    
    /// 将 UIImage 转换为 CVPixelBuffer
    ///
    /// - Parameter image: 输入图像
    /// - Returns: 处理后的像素缓冲区
    /// - Throws: `PreprocessError`
    public func process(_ image: UIImage) throws -> CVPixelBuffer {
        // 性能测量起点（仅作为占位，实际可使用 os_signpost）
        // let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let cgImage = image.cgImage else {
            throw PreprocessError.invalidImageData
        }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw PreprocessError.failedToCreatePixelBuffer(status: status)
        }
        
        // 锁定基地址
        let lockStatus = CVPixelBufferLockBaseAddress(buffer, [])
        guard lockStatus == kCVReturnSuccess else {
            throw PreprocessError.failedToLockPixelBuffer(status: lockStatus)
        }
        
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        // 创建绘图上下文
        // 注意：CVPixelBuffer 的上下文创建依赖于其锁定状态
        // 对于 kCVPixelFormatType_32BGRA，在 iOS (Little Endian) 上需要使用 byteOrder32Little | premultipliedFirst
        // 内存布局: B G R A -> 32位整数: 0xAARRGGBB
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            throw PreprocessError.failedToCreateContext
        }
        
        // 绘制图像（自动缩放/拉伸至目标尺寸）
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}

// MARK: - Error Handling

/// 预处理错误
public enum PreprocessError: Error, LocalizedError {
    case invalidImageData
    case failedToCreatePixelBuffer(status: CVReturn)
    case failedToLockPixelBuffer(status: CVReturn)
    case failedToCreateContext
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "输入的 UIImage 不包含有效的 CGImage 数据。"
        case .failedToCreatePixelBuffer(let status):
            return "创建 CVPixelBuffer 失败，错误码: \(status)。"
        case .failedToLockPixelBuffer(let status):
            return "锁定 CVPixelBuffer 基地址失败，错误码: \(status)。"
        case .failedToCreateContext:
            return "创建 CGContext 失败。"
        }
    }
}
#endif
