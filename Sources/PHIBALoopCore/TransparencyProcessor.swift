import CoreImage

public final class TransparencyProcessor: @unchecked Sendable {
    private let context = CIContext(options: [.cacheIntermediates: false])

    public init() {}

    public func process(
        _ image: CGImage,
        settings: ConversionSettings,
        outputSize: (width: Int, height: Int)
    ) -> CIImage {
        var result = CIImage(cgImage: image)
        let sx = CGFloat(outputSize.width) / result.extent.width
        let sy = CGFloat(outputSize.height) / result.extent.height
        result = result.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        if settings.effectiveTransparencyMode == .colorKey {
            result = result.applyingFilter("CIColorCube", parameters: [
                "inputCubeDimension": 32,
                "inputCubeData": colorCube(settings: settings)
            ])
        }

        if settings.effectiveTransparencyMode == .none {
            let color = settings.opaqueFillColor
            let background = CIImage(
                color: CIColor(red: color.red, green: color.green, blue: color.blue)
            ).cropped(to: result.extent)
            result = result.composited(over: background)
        }
        return result
    }

    public func render(_ image: CIImage, to buffer: CVPixelBuffer) {
        context.render(image, to: buffer, bounds: image.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    private func colorCube(settings: ConversionSettings) -> Data {
        let dimension = 32
        let tolerance = max(0.001, min(settings.keyTolerance, 0.95))
        let softness = max(0.001, min(settings.edgeSoftness, 0.5))
        var values = [Float]()
        values.reserveCapacity(dimension * dimension * dimension * 4)
        for blue in 0..<dimension {
            for green in 0..<dimension {
                for red in 0..<dimension {
                    let r = Double(red) / Double(dimension - 1)
                    var g = Double(green) / Double(dimension - 1)
                    let b = Double(blue) / Double(dimension - 1)
                    let distance = sqrt(
                        pow(r - settings.keyColor.red, 2)
                            + pow(g - settings.keyColor.green, 2)
                            + pow(b - settings.keyColor.blue, 2)
                    ) / sqrt(3)
                    let alpha = smoothstep(tolerance, tolerance + softness, distance)
                    if settings.reduceColorSpill, settings.keyColor.green > 0.5, alpha < 1 {
                        g = min(g, max(r, b) + (g - max(r, b)) * alpha)
                    }
                    values.append(Float(r))
                    values.append(Float(g))
                    values.append(Float(b))
                    values.append(Float(alpha))
                }
            }
        }
        return values.withUnsafeBytes { Data($0) }
    }

    private func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = max(0, min((value - edge0) / (edge1 - edge0), 1))
        return x * x * (3 - 2 * x)
    }
}
