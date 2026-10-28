import AppKit
import PHIBALoopCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: ConversionStore
    @State private var importing = false
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            taskList
                .navigationSplitViewColumnWidth(min: 230, ideal: 270)
        } content: {
            preview
                .navigationSplitViewColumnWidth(min: 380, ideal: 620)
        } detail: {
            inspector
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        }
        .frame(minWidth: 980, minHeight: 650)
        .toolbar {
            ToolbarItem {
                Button { importing = true } label: { Label("添加 GIF", systemImage: "plus") }
            }
            ToolbarItem {
                Button { store.removeSelected() } label: { Label("移除", systemImage: "trash") }
                    .disabled(store.selection.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.gif],
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result { store.importFiles(urls) }
        }
        .onDrop(of: [UTType.gif.identifier, UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            var accepted = false
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    accepted = true
                    provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                        guard let data,
                              let url = try? DroppedFileURLDecoder.decode(data) else { return }
                        Task { @MainActor in store.importFiles([url]) }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                    accepted = true
                    provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.gif.identifier) { url, _, _ in
                        guard let url else { return }
                        Task { @MainActor in store.importFiles([url]) }
                    }
                }
            }
            return accepted
        }
        .onOpenURL { url in
            store.importFiles([url])
        }
    }

    private var taskList: some View {
        VStack(spacing: 0) {
            if store.jobs.isEmpty {
                EmptyStateView(
                    title: "拖入 GIF",
                    systemImage: "photo.stack",
                    detail: "支持一次添加多个动画文件"
                )
            } else {
                List(store.jobs, selection: $store.selection) { job in
                    HStack(spacing: 10) {
                        Image(nsImage: job.thumbnail)
                            .resizable().scaledToFit()
                            .frame(width: 48, height: 48)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.sourceURL.lastPathComponent).lineLimit(1)
                            Text("\(job.metadata.width) × \(job.metadata.height) · \(job.metadata.frameCount) 帧")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(job.status.label).font(.caption2).foregroundStyle(statusColor(job.status))
                        }
                    }
                    .padding(.vertical, 3)
                    .tag(job.id)
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("导出到").font(.caption2).foregroundStyle(.secondary)
                    Text(store.outputDirectory.path)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .help(store.outputDirectory.path)
                }
                Spacer(minLength: 8)
                Button("更改…") { store.chooseOutputDirectory() }
            }
            .padding(12)
        }
    }

    private var preview: some View {
        ZStack {
            CheckerboardView()
            if let job = store.selectedJob {
                AnimatedGIFPreview(url: job.sourceURL)
                    .padding(44)
                    .id(job.id)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc").font(.system(size: 42)).foregroundStyle(.secondary)
                    Text("将 GIF 拖到窗口中开始").font(.title3)
                }
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 18).stroke(.blue, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .padding(16)
            }
        }
    }

    @ViewBuilder private var inspector: some View {
        if let job = store.selectedJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("导出设置").font(.title2.bold())
                    settingSection("格式") {
                        Picker("输出", selection: binding(\.outputFormat)) {
                            Text("HEVC MP4").tag(OutputFormat.hevcMP4)
                            Text("HEVC Alpha MOV").tag(OutputFormat.hevcAlphaMOV)
                        }.pickerStyle(.segmented)
                    }
                    settingSection("透明背景") {
                        Picker("处理方式", selection: binding(\.transparencyMode)) {
                            Text("关闭").tag(TransparencyMode.none)
                            Text("保留原透明").tag(TransparencyMode.preserveAlpha)
                            Text("纯色抠除").tag(TransparencyMode.colorKey)
                        }
                        .disabled(job.settings.outputFormat == .hevcMP4)
                        if job.settings.transparencyMode == .colorKey,
                           job.settings.outputFormat == .hevcAlphaMOV {
                            ColorPicker("背景颜色", selection: keyColorBinding)
                            slider("容差", value: binding(\.keyTolerance), range: 0.02...0.6)
                            slider("边缘柔化", value: binding(\.edgeSoftness), range: 0.01...0.3)
                            Toggle("减少绿色溢色", isOn: binding(\.reduceColorSpill))
                        }
                    }
                    settingSection("尺寸") {
                        Picker("缩放", selection: scaleBinding) {
                            Text("原始").tag(1.0)
                            Text("75%").tag(0.75)
                            Text("50%").tag(0.5)
                        }.pickerStyle(.segmented)
                        HStack {
                            Text("自定义")
                            TextField("宽", value: customWidthBinding, format: .number)
                                .frame(width: 64)
                            Text("×")
                            TextField("高", value: customHeightBinding, format: .number)
                                .frame(width: 64)
                        }
                    }
                    settingSection("帧率与质量") {
                        Picker("帧率", selection: frameRateBinding) {
                            Text("保持原始").tag(0)
                            Text("24 fps").tag(24)
                            Text("30 fps").tag(30)
                            Text("60 fps").tag(60)
                        }
                        Picker("质量", selection: binding(\.quality)) {
                            Text("小体积").tag(QualityPreset.compact)
                            Text("平衡").tag(QualityPreset.balanced)
                            Text("高质量").tag(QualityPreset.high)
                        }
                        Stepper("重复 \(job.settings.repeatCount) 次", value: binding(\.repeatCount), in: 1...20)
                    }
                    if case let .failed(message) = job.status {
                        Text(message).font(.caption).foregroundStyle(.red)
                    }
                    if case let .completed(url) = job.status {
                        Button("在 Finder 中显示") { store.reveal(url) }
                    }
                    if store.isRunning {
                        Button(role: .destructive) { store.cancel() } label: {
                            Label("取消转换", systemImage: "stop.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    } else {
                        Button { store.start() } label: {
                            Label("开始转换", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(store.jobs.isEmpty)
                    }
                }
                .padding(22)
            }
        } else {
            EmptyStateView(title: "尚未选择动画", systemImage: "slider.horizontal.3")
        }
    }

    private func settingSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ConversionSettings, Value>) -> Binding<Value> {
        Binding(
            get: { store.selectedJob?.settings[keyPath: keyPath] ?? fallbackValue(keyPath) },
            set: { value in store.updateSelected { $0[keyPath: keyPath] = value } }
        )
    }

    private func fallbackValue<Value>(_ keyPath: WritableKeyPath<ConversionSettings, Value>) -> Value {
        ConversionSettings()[keyPath: keyPath]
    }

    private var scaleBinding: Binding<Double> {
        Binding(
            get: {
                guard let setting = store.selectedJob?.settings.outputScale else { return 1 }
                if case let .percentage(value) = setting { return value }
                return 1
            },
            set: { value in store.updateSelected { $0.outputScale = value == 1 ? .original : .percentage(value) } }
        )
    }

    private var frameRateBinding: Binding<Int> {
        Binding(
            get: {
                guard let mode = store.selectedJob?.settings.frameRateMode else { return 0 }
                if case let .fixed(value) = mode { return value }
                return 0
            },
            set: { value in store.updateSelected { $0.frameRateMode = value == 0 ? .originalTiming : .fixed(value) } }
        )
    }

    private var customWidthBinding: Binding<Int> {
        Binding(
            get: {
                guard let job = store.selectedJob else { return 2 }
                if case let .custom(width, _) = job.settings.outputScale { return width }
                return job.metadata.width
            },
            set: { width in
                let height = customHeightBinding.wrappedValue
                store.updateSelected { $0.outputScale = .custom(width: max(2, width), height: max(2, height)) }
            }
        )
    }

    private var customHeightBinding: Binding<Int> {
        Binding(
            get: {
                guard let job = store.selectedJob else { return 2 }
                if case let .custom(_, height) = job.settings.outputScale { return height }
                return job.metadata.height
            },
            set: { height in
                let width = customWidthBinding.wrappedValue
                store.updateSelected { $0.outputScale = .custom(width: max(2, width), height: max(2, height)) }
            }
        )
    }

    private var keyColorBinding: Binding<Color> {
        Binding(
            get: {
                let value = store.selectedJob?.settings.keyColor ?? .green
                return Color(red: value.red, green: value.green, blue: value.blue)
            },
            set: { color in
                let ns = NSColor(color).usingColorSpace(.sRGB) ?? .green
                store.updateSelected { $0.keyColor = RGBColor(red: ns.redComponent, green: ns.greenComponent, blue: ns.blueComponent) }
            }
        )
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Slider(value: value, in: range)
        }
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .ready: .secondary
        case .converting: .blue
        case .completed: .green
        case .failed: .red
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var detail: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct CheckerboardView: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 18
            for row in 0...Int(size.height / cell) {
                for column in 0...Int(size.width / cell) where (row + column).isMultiple(of: 2) {
                    context.fill(
                        Path(CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)),
                        with: .color(.gray.opacity(0.12))
                    )
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
