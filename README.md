# SmartPhone AI Vision Engine (SPAIVE)

**SPAIVE** is a high-performance, lightweight object detection engine for iOS, powered by Apple’s Core ML and Vision frameworks with integrated YOLOv11n model for easy image/video analysis.

## ✨ Features

* **Performance**: Deep Core ML optimization, leveraging the Apple Neural Engine (ANE) and GPU.
* **Easy to Use**: Unified Swift API (`SPAIVE`), supports Swift Concurrency (async/await).
* **Core Functions**:
    * **Single Image Detection**: Fast static image analysis.
    * **Batch Processing**: Concurrent detection over image arrays.
    * **Video Analysis**: Real-time/offline frame-by-frame detection; streaming results supported.
    * **Visualization**: Built-in fast drawing tools, customizable styles.
* **Thread-Safe**: Actor-based core for safe multitasking.
* **Lightweight**: Pure Swift, no heavy third-party dependencies.

## 📱 Requirements

* iOS 26.0
* Swift 5.9+
* Xcode 15.0+

## 📦 Installation

**Swift Package Manager:**

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/founderlin/SmartPhone-AI-Vision-Engine.git", from: "1.0.0")
]
```
Or use `File > Add Packages...` in Xcode.

## 🚀 Quick Start

```swift
import SPAIVE
import UIKit

let image = UIImage(named: "test.jpg")!
let result = try await SPAIVE.detect(image: image)
print("Detected \(result.objects.count) objects.")
```

## 🎨 Visualize Results

```swift
let annotated = SPAIVE.annotate(image: image, with: result.objects, style: .default)
imageView.image = annotated
```

## 🛠 Advanced

**Custom config:**

```swift
var config = SPAIVEConfiguration()
config.confidenceThreshold = 0.5
let result = try await SPAIVE.detect(image: image, configuration: config)
```

**Video Detection Example:**

```swift
for try await progress in try await SPAIVE.detect(videoURL: videoURL, fps: 10) {
    print(progress.percentage)
}
```

**Batch Images:**

```swift
let service = try await DetectionService()
let results = try await service.detectBatch(images: images)
```

## 📈 Tips

1. Reuse `DetectionService` for frequent detection.
2. Images are resized to 640x640 by default.
3. 5–10 FPS is usually enough for video analysis.

## ❓ FAQ

* **Bounding Boxes:** SPAIVE uses UIKit coordinate system (origin at top-left, in pixels).
* **Model not found?** Ensure `yolo11n.mlmodelc` is included in your App Bundle or via SPM.
* **Supported Classes:** COCO dataset, 80 common object types.

## 📄 License

Apache License 2.0. See [LICENSE](LICENSE).

## 🤝 Contributing

PRs and issues are welcome!
