#if canImport(UIKit)
import UIKit

/// 可视化样式配置
public struct VisualizationStyle {
    
    // MARK: - Color Scheme
    
    public enum ColorScheme {
        /// 每个类别固定一种颜色（根据标签哈希值或索引）
        case byLabel
        /// 根据置信度渐变（低置信度为冷色，高置信度为暖色）
        case byConfidence
        /// 统一使用固定颜色
        case fixed(UIColor)
    }
    
    // MARK: - Properties
    
    /// 边框线宽
    public let lineWidth: CGFloat
    
    /// 标签字体
    public let font: UIFont
    
    /// 标签背景透明度 [0, 1]
    public let labelBackgroundAlpha: CGFloat
    
    /// 标签文字颜色
    public let labelTextColor: UIColor
    
    /// 颜色策略
    public let colorScheme: ColorScheme
    
    /// 是否显示置信度
    public let showConfidence: Bool
    
    /// 是否显示标签文本
    public let showLabel: Bool
    
    // MARK: - Default Styles
    
    /// 默认样式：按类别着色，线宽 3.0，显示标签和置信度
    public static let `default` = VisualizationStyle(
        lineWidth: 3.0,
        font: .boldSystemFont(ofSize: 14),
        labelBackgroundAlpha: 0.7,
        labelTextColor: .white,
        colorScheme: .byLabel,
        showConfidence: true,
        showLabel: true
    )
    
    /// 简洁样式：仅边框，按类别着色
    public static let minimal = VisualizationStyle(
        lineWidth: 2.0,
        font: .systemFont(ofSize: 10),
        labelBackgroundAlpha: 0.0,
        labelTextColor: .clear,
        colorScheme: .byLabel,
        showConfidence: false,
        showLabel: false
    )
    
    // MARK: - Initialization
    
    public init(
        lineWidth: CGFloat,
        font: UIFont,
        labelBackgroundAlpha: CGFloat,
        labelTextColor: UIColor,
        colorScheme: ColorScheme,
        showConfidence: Bool,
        showLabel: Bool
    ) {
        self.lineWidth = lineWidth
        self.font = font
        self.labelBackgroundAlpha = labelBackgroundAlpha
        self.labelTextColor = labelTextColor
        self.colorScheme = colorScheme
        self.showConfidence = showConfidence
        self.showLabel = showLabel
    }
}

/// 检测结果可视化工具
///
/// 负责将检测到的目标框绘制在图像上。
/// 不依赖于具体的检测逻辑，仅处理渲染。
public struct DetectionVisualizer {
    
    // MARK: - Properties
    
    public let style: VisualizationStyle
    
    // MARK: - Initialization
    
    public init(style: VisualizationStyle = .default) {
        self.style = style
    }
    
    // MARK: - Public API
    
    /// 在图像上绘制检测框
    /// - Parameters:
    ///   - image: 原始图像
    ///   - objects: 检测对象列表
    /// - Returns: 带标注的合成图像。如果绘制失败，返回原图。
    public func annotate(
        image: UIImage,
        with objects: [DetectedObject]
    ) -> UIImage {
        let imageSize = image.size
        let scale = image.scale
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        // 1. 绘制原图
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        
        // 2. 绘制每个检测对象
        context.setLineWidth(style.lineWidth)
        
        for (index, object) in objects.enumerated() {
            // 计算边界框（DetectedObject 已经是 UIKit 像素坐标）
            let box = object.boundingBox
            
            // 获取颜色
            let color = colorFor(object: object, index: index)
            
            // 绘制边框
            context.setStrokeColor(color.cgColor)
            context.stroke(box)
            
            // 如果需要显示标签或置信度
            if style.showLabel || style.showConfidence {
                drawLabel(
                    context: context,
                    object: object,
                    boundingBox: box,
                    color: color
                )
            }
        }
        
        // 3. 获取合成图像
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }
        
        return resultImage
    }
    
    // MARK: - Private Helpers
    
    private func drawLabel(
        context: CGContext,
        object: DetectedObject,
        boundingBox: CGRect,
        color: UIColor
    ) {
        // 构建文本
        var labelText = ""
        if style.showLabel {
            labelText += object.label
        }
        if style.showConfidence {
            if !labelText.isEmpty { labelText += " " }
            labelText += object.formattedConfidence
        }
        
        guard !labelText.isEmpty else { return }
        
        // 计算文本尺寸
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.labelTextColor
        ]
        
        let labelSize = (labelText as NSString).size(withAttributes: attributes)
        
        // 计算背景矩形
        // 默认显示在框的左上方，如果超出上边界则显示在框内左上方
        var labelOriginY = boundingBox.origin.y - labelSize.height - 4
        if labelOriginY < 0 {
            labelOriginY = boundingBox.origin.y
        }
        
        let labelRect = CGRect(
            x: boundingBox.origin.x,
            y: labelOriginY,
            width: labelSize.width + 8,
            height: labelSize.height + 4
        )
        
        // 绘制背景
        if style.labelBackgroundAlpha > 0 {
            context.setFillColor(color.withAlphaComponent(style.labelBackgroundAlpha).cgColor)
            context.fill(labelRect)
        }
        
        // 绘制文字
        (labelText as NSString).draw(
            at: CGPoint(x: labelRect.origin.x + 4, y: labelRect.origin.y + 2),
            withAttributes: attributes
        )
    }
    
    private func colorFor(object: DetectedObject, index: Int) -> UIColor {
        switch style.colorScheme {
        case .fixed(let color):
            return color
            
        case .byConfidence:
            // 简单实现：0.0 -> Red, 1.0 -> Green
            let hue = CGFloat(object.confidence) * 0.33 // 0 (Red) to 0.33 (Green)
            return UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            
        case .byLabel:
            // 使用标签哈希值生成稳定的颜色
            let hash = abs(object.label.hashValue)
            let colors: [UIColor] = [
                .red, .blue, .green, .orange, .purple,
                .systemPink, .yellow, .cyan, .magenta, .brown
            ]
            return colors[hash % colors.count]
        }
    }
}
#endif
