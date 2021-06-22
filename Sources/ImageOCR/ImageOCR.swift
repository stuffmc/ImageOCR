import CoreImage
import Vision

public struct ImageOCR {
    var inputImage: CIImage?

    var string: String? {
        guard let inputImage = inputImage else {
            return nil
        }
        let requestHandler = VNImageRequestHandler(ciImage: inputImage)
        let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
        do {
            try requestHandler.perform([documentDetectionRequest])
        } catch {
            print(error)
            return nil
        }
        guard let document = documentDetectionRequest.results?.first,
              let documentImage = perspectiveCorrectedImage(
                from: inputImage,
                rectangleObservation: document) else {
                  fatalError("Unable to get document image.")
              }
        let documentRequestHandler = VNImageRequestHandler(ciImage: documentImage)
        var textBlocks: [VNRecognizedTextObservation] = []
        let ocrRequest = VNRecognizeTextRequest { request, _ in
            textBlocks = request.results as? [VNRecognizedTextObservation] ?? []
        }
        // At this point, the block in the VNRecognizeTextRequest
        // has not been executed. textBlock will always be empty
//        if textBlocks.isEmpty {
//            return nil
//        }
        do {
            try documentRequestHandler.perform([ocrRequest])
        } catch {
            print(error)
        }
        textBlocks.forEach {
            if let first = $0.topCandidates(1).first {
                print(first.string)
            } else {
                print("OCR: no top candidates found")
            }
        }
        return textBlocks.first?.topCandidates(1).first?.string
    }

    private func perspectiveCorrectedImage(
        from inputImage: CIImage,
        rectangleObservation: VNRectangleObservation
    )
    -> CIImage? {
        let imageSize = inputImage.extent.size

        // Verify detected rectangle is valid.
        let boundingBox = rectangleObservation.boundingBox.scaled(to: imageSize)
        guard inputImage.extent.contains(boundingBox) else {
            print("invalid detected rectangle")
            return nil
        }
        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = rectangleObservation.topLeft.scaled(to: imageSize)
        let topRight = rectangleObservation.topRight.scaled(to: imageSize)
        let bottomLeft = rectangleObservation.bottomLeft.scaled(to: imageSize)
        let bottomRight = rectangleObservation.bottomRight.scaled(to: imageSize)
        let correctedImage = inputImage
            .cropped(to: boundingBox)
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        return correctedImage
    }
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
