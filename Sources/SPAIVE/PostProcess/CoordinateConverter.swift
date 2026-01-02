import Foundation
import CoreGraphics

/// 坐标转换器
///
/// 负责在 Vision 归一化坐标系与 UIKit 像素坐标系之间进行转换。
public struct CoordinateConverter {
    
    /// Vision 归一化坐标转 UIKit 像素坐标
    ///
    /// Vision 框架使用归一化坐标系，原点在左下角，范围 [0, 1]。
    /// UIKit 框架使用像素坐标系，原点在左上角。
    ///
    /// - Parameters:
    ///   - normalizedBox: Vision 坐标（原点左下，范围 [0,1]）
    ///   - imageSize: 原始图像尺寸
    /// - Returns: UIKit 坐标（原点左上，像素单位）
    public static func visionToUIKit(
        normalizedBox: CGRect,
        imageSize: CGSize
    ) -> CGRect {
        // Vision (左下原点) -> UIKit (左上原点)
        // x' = x * width
        // y' = (1 - y - height) * height  <-- 注意这里，Vision 的 y 是底部距离，转换后是顶部距离
        // w' = w * width
        // h' = h * height
        
        let x = normalizedBox.origin.x * imageSize.width
        let y = (1.0 - normalizedBox.origin.y - normalizedBox.height) * imageSize.height
        let width = normalizedBox.width * imageSize.width
        let height = normalizedBox.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
