# SPAIVE API Documentation

SPAIVE (Smart Phone AI Vision Engine) is a high-performance object detection engine based on Core ML and Vision frameworks. It encapsulates the YOLO11n model, providing a complete solution from model [...]

## 1. Architecture

The project adopts a layered architecture, providing a unified entry point through the `SPAIVE` facade pattern. The underlying logic is decoupled into `Core`, `PreProcess`, `PostProcess`, and `Video` [...]

```mermaid
graph TD
    User[Client_App] --> API[SPAIVE (Facade API)]
    
    subgraph Public_Interface
        API --> DS[DetectionService]
        API --> VDS[VideoDetectionService]
        API --> VIS[DetectionVisualizer]
    end
    
    subgraph Core_Logic
        DS --> ML[ModelLoader]
        DS --> PRE[ImagePreprocessor]
        DS --> POST[DetectionPostProcessor]
        VDS --> DS
        VDS --> VFE[VideoFrameExtractor]
    end
    
    subgraph Data_Processing
        POST --> NMS[NMSProcessor]
        POST --> CC[CoordinateConverter]
        ML --> CML[CoreML Model (yolo11n)]
    end
    
    subgraph Models
        Config[DetectionConfiguration]
        Result[DetectionResult]
        Object[DetectedObject]
    end
    
    DS -.-> Config
    DS -.-> Result
```

## 2. Features

The library provides the following core capabilities:

1.  **Image Detection**
    *   Supports asynchronous single-image object detection.
    *   Supports batch image detection with progress callbacks.
    *   Automatically handles image scaling, cropping, and normalization.

2.  **Video Detection**
    *   Supports streaming processing of local video files (`AsyncThrowingStream`).
    *   Supports custom frame extraction frequency (FPS).
    *   Returns detection results, timestamps, and progress information for each frame in real-time.

3.  **Visualization**
    *   Provides convenient APIs to draw Bounding Boxes and class labels on the original image.
    *   Supports custom drawing styles.

4.  **Configuration**
    *   Customizable Confidence Threshold.
    *   Customizable IoU Threshold (NMS Threshold).
    *   Customizable model input size.

5.  **Concurrency Safety**
    *   Core services (`DetectionService`, `VideoDetectionService`) are implemented using Swift Actors to ensure safety in multi-threaded environments.

## 3. API Reference

### Unified Entry Point (SPAIVE Facade)
The most commonly used static methods, suitable for quick integration.

| Method Signature | Description |
| :--- | :--- |
| `SPAIVE.detect(image:configuration:)` | **Single Image Detection**. Asynchronously detects objects in a single image, returning `SPAIVEResult`. |
| `SPAIVE.detect(videoURL:fps:configuration:)` | **Video Detection**. Returns `AsyncThrowingStream<VideoDetectionProgress, Error>`, containing results for each frame. |
| `SPAIVE.annotate(image:with:style:)` | **Visualization**. Draws detection results on the image, returning a new `UIImage`. |

### Core Service (DetectionService)
Suitable for scenarios requiring fine-grained control or high-frequency reuse.

| Method Signature | Description |
| :--- | :--- |
| `init(configuration:)` | Initializes the service and asynchronously loads the model. |
| `detect(image:)` | Asynchronously detects objects in a single image. |
| `detect(image:completion:)` | Synchronous/Callback-style detection method (bridge for non-async code). |
| `detectBatch(images:progress:)` | Batch detects an array of images, providing a progress callback. |

### Video Service (VideoDetectionService)

| Method Signature | Description |
| :--- | :--- |
| `init(configuration:)` | Initializes the video service. |
| `detect(videoURL:fps:)` | Starts video stream detection, analyzing frames at the specified FPS. |

### Data Models

*   **SPAIVEConfiguration (DetectionConfiguration)**: Model parameters configuration (e.g., `confidenceThreshold: 0.25`, `iouThreshold: 0.45`).
*   **SPAIVEResult (DetectionResult)**: Contains the list of detected objects (`objects`), processing time (`processingTime`), and original image size.
*   **SPAIVEObject (DetectedObject)**: A single detected object, containing `label` (class), `confidence` (score), `boundingBox` (normalized coordinates), and `rect` (pixel coordinates).
