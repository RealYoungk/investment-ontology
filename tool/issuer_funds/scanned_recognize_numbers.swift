import Foundation
import ImageIO
import Vision

// Local read-only OCR candidate evidence. Never posts or corrects financial data.
guard CommandLine.arguments.count == 2 else { exit(2) }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(3) }
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en-US"]
request.usesLanguageCorrection = false
try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
let rows: [[String: Any]] = (request.results ?? []).compactMap { observation in
    guard let candidate = observation.topCandidates(1).first else { return nil }
    let bounds = observation.boundingBox
    return ["text": candidate.string, "confidence": candidate.confidence,
            "x": bounds.origin.x, "y": bounds.origin.y,
            "width": bounds.width, "height": bounds.height]
}
let result: [String: Any] = ["automaticPosting": false, "numericValidated": false,
                           "engine": "Apple Vision local accurate, language correction disabled",
                           "imagePath": url.path, "rows": rows]
let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(data)
