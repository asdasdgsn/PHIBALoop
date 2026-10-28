import AppKit
import Foundation
import PHIBALoopCore

enum JobStatus: Equatable {
    case ready
    case converting(Double)
    case completed(URL)
    case failed(String)

    var label: String {
        switch self {
        case .ready: "等待转换"
        case let .converting(progress): "转换中 \(Int(progress * 100))%"
        case .completed: "已完成"
        case .failed: "转换失败"
        }
    }
}

struct ConversionJob: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let metadata: GIFMetadata
    let thumbnail: NSImage
    var settings = ConversionSettings()
    var status: JobStatus = .ready
}

@MainActor
final class ConversionStore: ObservableObject {
    @Published var jobs: [ConversionJob] = []
    @Published var selection: Set<UUID> = []
    @Published var outputDirectory: URL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
    @Published var isRunning = false
    @Published private(set) var lastExportedURL: URL?

    private let decoder = GIFDecoder()
    private let encoder = HEVCEncoder()
    private var conversionTask: Task<Void, Never>?

    var selectedJobID: UUID? { selection.first ?? jobs.first?.id }
    var selectedJob: ConversionJob? { jobs.first { $0.id == selectedJobID } }

    func importFiles(_ urls: [URL]) {
        for url in urls where !jobs.contains(where: { $0.sourceURL.standardizedFileURL == url.standardizedFileURL }) {
            do {
                let metadata = try decoder.inspect(url: url)
                let frame = try decoder.firstFrame(url: url)
                let thumbnail = NSImage(cgImage: frame, size: NSSize(width: frame.width, height: frame.height))
                let job = ConversionJob(sourceURL: url, metadata: metadata, thumbnail: thumbnail)
                jobs.append(job)
                if selection.isEmpty { selection = [job.id] }
            } catch {
                NSSound.beep()
            }
        }
    }

    func updateSelected(_ update: (inout ConversionSettings) -> Void) {
        let targets = selection.isEmpty ? Set(selectedJobID.map { [$0] } ?? []) : selection
        for index in jobs.indices where targets.contains(jobs[index].id) {
            update(&jobs[index].settings)
        }
    }

    func removeSelected() {
        jobs.removeAll { selection.contains($0.id) }
        selection.removeAll()
        if let first = jobs.first { selection = [first.id] }
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择导出文件夹"
        panel.directoryURL = outputDirectory
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.standardizedFileURL
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let exportDirectory = outputDirectory.standardizedFileURL
        conversionTask = Task {
            let didAccessSecurityScope = exportDirectory.startAccessingSecurityScopedResource()
            defer {
                if didAccessSecurityScope {
                    exportDirectory.stopAccessingSecurityScopedResource()
                }
            }
            for id in jobs.map(\.id) {
                guard let index = jobs.firstIndex(where: { $0.id == id }) else { continue }
                if case .completed = jobs[index].status { continue }
                let source = jobs[index].sourceURL
                let settings = jobs[index].settings
                let destination = ExportDestination.availableURL(
                    source: source,
                    directory: exportDirectory,
                    format: settings.outputFormat
                )
                jobs[index].status = .converting(0)
                do {
                    try await encoder.encode(source: source, destination: destination, settings: settings) { progress in
                        Task { @MainActor [weak self] in
                            guard let self,
                                  let liveIndex = self.jobs.firstIndex(where: { $0.id == id }) else { return }
                            self.jobs[liveIndex].status = .converting(progress)
                        }
                    }
                    let dimensions = settings.outputDimensions(
                        sourceWidth: jobs[index].metadata.width,
                        sourceHeight: jobs[index].metadata.height
                    )
                    try await ExportVerifier.verify(
                        url: destination,
                        expectedWidth: dimensions.width,
                        expectedHeight: dimensions.height,
                        expectedDuration: jobs[index].metadata.duration * Double(settings.repeatCount)
                    )
                    if let liveIndex = jobs.firstIndex(where: { $0.id == id }) {
                        jobs[liveIndex].status = .completed(destination)
                        lastExportedURL = destination
                    }
                } catch {
                    if let liveIndex = jobs.firstIndex(where: { $0.id == id }) {
                        jobs[liveIndex].status = .failed(error.localizedDescription)
                    }
                }
            }
            isRunning = false
            conversionTask = nil
        }
    }

    func cancel() {
        conversionTask?.cancel()
        conversionTask = nil
        isRunning = false
        for index in jobs.indices {
            if case .converting = jobs[index].status { jobs[index].status = .ready }
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
