import XCTest

@testable import ImageOCR

final class ImageOCRTests: XCTestCase {
    func testExample() throws {
        guard let asset = NSDataAsset(name: "MagSafe", bundle: .module) else {
            XCTFail()
            return
        }
        guard let image = CIImage(data: asset.data) else {
            XCTFail()
            return
        }
        // Your code only returns the first string of the first
        // Top candidate
        XCTAssertEqual(ImageOCR(inputImage: image).string, "85W MagSafe 2")
    }
}
