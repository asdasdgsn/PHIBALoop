import Foundation

public enum DroppedFileURLDecoderError: Error {
    case invalidRepresentation
}

public enum DroppedFileURLDecoder {
    public static func decode(_ data: Data) throws -> URL {
        guard let value = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: value),
              url.isFileURL else {
            throw DroppedFileURLDecoderError.invalidRepresentation
        }
        return url
    }
}
