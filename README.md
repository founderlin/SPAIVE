# SmartPhone AI Vision Engine (SPAIVE)

**SPAIVE** 是一个高性能、轻量级目标检测引擎（目前仅针对 iOS 设备）。
基于 Apple 的 Core ML 和 Vision 框架，集成了 YOLOv11n 模型，提供开箱即用的图像与视频分析能力。

## ✨ 主要特性

*   **高性能**: 基于 Core ML 深度优化，充分利用 Apple Neural Engine (ANE) 和 GPU 加速。
*   **易用性**: 提供统一且简洁的 Swift API (`SPAIVE`)，支持 Swift Concurrency (async/await)。
*   **全功能**:
    *   📷 **单图检测**: 快速分析静态图像。
    *   🎞️ **批量处理**: 高效并发处理图像队列。
    *   🎥 **视频流分析**: 实时/离线视频逐帧检测，支持流式结果返回。
    *   🎨 **可视化**: 内置高性能绘图工具，支持自定义样式。
*   **线程安全**: 核心服务采用 Actor 模型设计，确保多线程环境下的安全性。
*   **轻量级**: 纯 Swift 实现，无第三方重型依赖。

## 📱 系统要求

*   iOS 16.0+ / iPadOS 16.0+
*   Swift 5.9+
*   Xcode 15.0+

## 📦 安装说明

### Swift Package Manager

在你的 `Package.swift` 文件中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/founderlin/SmartPhone-AI-Vision-Engine.git", from: "1.0.0")
]
```

或者在 Xcode 中选择 `File > Add Packages...` 并输入仓库 URL。

## 🚀 快速开始

### 1. 导入模块

```swift
import SPAIVE
import UIKit
```

### 2. 单图检测

```swift
// 准备图片
guard let image = UIImage(named: "test.jpg") else { return }

// 执行检测
do {
    let result = try await SPAIVE.detect(image: image)
    
    print("检测到 \(result.objects.count) 个目标:")
    for object in result.objects {
        print("- \(object.label): \(object.formattedConfidence)")
    }
} catch {
    print("检测失败: \(error)")
}
```

### 3. 结果可视化

```swift
// 绘制检测框和标签
let annotatedImage = SPAIVE.annotate(
    image: image,
    with: result.objects,
    style: .default // 或 .minimal, .custom(...)
)

// 显示结果
imageView.image = annotatedImage
```

## 🛠 高级用法

### 自定义配置

你可以通过 `SPAIVEConfiguration` (即 `DetectionConfiguration`) 调整检测参数：

```swift
var config = SPAIVEConfiguration()
config.confidenceThreshold = 0.5 // 提高置信度阈值
config.iouThreshold = 0.45       // 调整 NMS 阈值
config.modelName = "yolo11n"     // 指定模型名称

let result = try await SPAIVE.detect(image: image, configuration: config)
```

### 视频流检测

使用流式 API 逐帧处理视频，支持实时进度反馈：

```swift
let videoURL = URL(fileURLWithPath: "path/to/video.mp4")

do {
    // 以 10 FPS 的速率处理视频
    for try await progress in try await SPAIVE.detect(videoURL: videoURL, fps: 10) {
        print("处理进度: \(Int(progress.percentage * 100))%")
        print("当前帧检测到: \(progress.result.objects.count) 个目标")
        
        // 你可以在这里实时处理每一帧的结果
    }
    print("视频处理完成")
} catch {
    print("视频处理出错: \(error)")
}
```

### 批量图像处理

对于大量图片，建议使用 `DetectionService` 的批量接口以获得更好的性能：

```swift
let service = try await DetectionService()
let images = [image1, image2, image3]

let results = try await service.detectBatch(images: images) { progress in
    print("批量处理进度: \(progress)")
}
```

## 📈 性能优化建议

1.  **复用 Service**: 如果需要频繁检测，请实例化并持有 `DetectionService`，而不是每次调用 `SPAIVE.detect`（后者每次都会重新加载模型）。
2.  **图像尺寸**: 模型输入默认调整为 640x640。输入图片过大仅会增加预处理耗时，不会显著提升精度。
3.  **视频 FPS**: 处理视频时，根据实际需求设置 FPS。通常 5-10 FPS 足以进行轨迹跟踪或统计，无需逐帧处理（30/60 FPS）。

## ❓ 常见问题

### Q: 坐标系是怎样的？
A: `SPAIVE` 返回的 `boundingBox` 使用标准的 **UIKit 坐标系**（原点在左上角），单位为**像素 (Pixel)**。你可以直接在 `UIView` 或 `CALayer` 中使用，无需归一化转换。

### Q: 如何处理 "Model not found" 错误？
A: 请确保 `yolo11n.mlmodelc` 文件夹已包含在你的 App Bundle 中。如果你是通过 SPM 引入，它应该会自动包含在 `SPAIVE_SPAIVE.bundle` 中。

### Q: 支持哪些目标类别？
A: 当前内置的 YOLOv11n 模型支持 COCO 数据集的 80 种常见物体（如 person, car, dog, chair 等）。

## 📄 许可证

本项目采用 **Apache License 2.0** 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 贡献指南

欢迎提交 Pull Request 或 Issue！

1.  Fork 本仓库
2.  创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3.  提交你的修改 (`git commit -m 'Add some AmazingFeature'`)
4.  推送到分支 (`git push origin feature/AmazingFeature`)
5.  开启一个 Pull Request
