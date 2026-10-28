import Foundation

public enum ExportDestination {
    public static func availableURL(
        source: URL,
        directory: URL,
        format: OutputFormat,
        fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)
    ) -> URL {
        let stem = source.deletingPathExtension().lastPathComponent
        var suffix = 1
        while true {
            let name = suffix == 1 ? stem : "\(stem)-\(suffix)"
            let candidate = directory
                .appendingPathComponent(name)
                .appendingPathExtension(format.fileExtension)
            if candidate.standardizedFileURL != source.standardizedFileURL,
               !fileExists(candidate.path) {
                return candidate
            }
            suffix += 1
        }
    }
}
