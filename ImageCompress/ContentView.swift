import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputPath: String = ""
    @State private var outputPath: String = ""
    @State private var quality: Double = 85
    @State private var isCompressing: Bool = false
    @State private var outputSize: String = ""
    @State private var inputSize: String = ""
    @State private var estimatedSize: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    private let gradientColors: [Color] = [.blue, .purple]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("图片压缩工具")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("轻松压缩您的图片，保持最佳质量")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Main Content
            VStack(spacing: 20) {
                // Input File Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("输入文件", systemImage: "photo")
                            .font(.headline)
                        
                        HStack {
                            Text(inputPath.isEmpty ? "未选择文件" : inputPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("选择图片") {
                                chooseInputFile()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !inputSize.isEmpty {
                            Text("原始大小：\(inputSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Quality Settings
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("压缩质量", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: $quality, in: 0...100, step: 5)
                                .tint(gradientColors[0])
                                .onChange(of: quality) { _, newValue in
                                    if let originalSize = try? FileManager.default.attributesOfItem(atPath: inputPath)[.size] as? Double {
                                        // 使用简单的线性关系估算，实际压缩比会更复杂
                                        let estimatedBytes = originalSize * (newValue / 100.0)
                                        estimatedSize = String(format: "预计压缩后：%.2f KB", estimatedBytes / 1024.0)
                                    }
                                }
                            
                            Text("\(Int(quality))%")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                                .frame(width: 50)
                        }
                        
                        Text("质量越高，文件越大")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !estimatedSize.isEmpty {
                            Text("\(estimatedSize)（注意：实际压缩大小会略有差异）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Output Path Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("输出位置", systemImage: "folder")
                            .font(.headline)
                        
                        HStack {
                            Text(outputPath.isEmpty ? "未选择保存位置" : outputPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("选择位置") {
                                chooseOutputPath()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Compress Button
            Button(action: compressImage) {
                if isCompressing {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text("开始压缩")
                        .font(.headline)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isCompressing || inputPath.isEmpty || outputPath.isEmpty)
            
            // Output Size
            if !outputSize.isEmpty {
                GroupBox {
                    HStack {
                        Label("压缩结果", systemImage: "arrow.down.circle")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(outputSize)
                            .monospacedDigit()
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                    Button {
                        NSWorkspace.shared.selectFile(outputPath, inFileViewerRootedAtPath: "")
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")  // 添加文件夹图标
                                .imageScale(.medium)
                            Text("在文件夹中显示")
                        }
                        .frame(maxWidth: .infinity)  // 让按钮填充可用宽度
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)  // 使用bordered样式
                    .controlSize(.regular)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // 选择输入文件
    private func chooseInputFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.jpeg, .png]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "请选择要压缩的图片"
        openPanel.prompt = "选择"
        
        guard let window = NSApplication.shared.windows.first else { return }
        
        openPanel.beginSheetModal(for: window) { result in
            if result == .OK, let url = openPanel.url {
                DispatchQueue.main.async {
                    inputPath = url.path
                    // 计算输入文件大小
                    if let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int {
                        inputSize = String(format: "%.2f KB", Double(fileSize) / 1024.0)
                    } else {
                        inputSize = "未知"
                    }
                }
            }
        }
    }
    
    // 选择输出路径
    private func chooseOutputPath() {
        let savePanel = NSSavePanel()
        
        if let jpegType = UTType(filenameExtension: "jpg") {
            savePanel.allowedContentTypes = [jpegType]
        }
        
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "compressed_image.jpg"
        savePanel.message = "选择压缩后图片的保存位置"
        savePanel.prompt = "保存"
        
        savePanel.begin { response in
            if response == .OK {
                guard let url = savePanel.url else { return }
                DispatchQueue.main.async {
                    self.outputPath = url.path
                }
            }
        }
    }
    
    // 压缩相关函数保持不变...
    private func compressImage() {
        isCompressing = true
        outputSize = "处理中..."
        
        guard !inputPath.isEmpty, !outputPath.isEmpty else {
            isCompressing = false
            return
        }
        
        guard let inputImage = NSImage(contentsOfFile: inputPath) else {
            isCompressing = false
            return
        }
        
        if let compressedImage = compress(inputImage: inputImage) {
            saveImage(compressedImage)
        } else {
            isCompressing = false
        }
    }
    
    private func compress(inputImage: NSImage) -> NSImage? {
        let qualityFactor = quality / 100.0
        
        let size = inputImage.size
        let rect = NSRect(x: 0, y: 0, width: size.width * qualityFactor, height: size.height * qualityFactor)
        
        guard let imageData = inputImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData) else {
            return nil
        }
        
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: qualityFactor
        ]
        
        guard let compressedData = bitmap.representation(using: .jpeg, properties: properties) else {
            return nil
        }
        
        return NSImage(data: compressedData)
    }
    
    private func saveImage(_ image: NSImage) {
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData) else {
            isCompressing = false
            return
        }
        
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality / 100.0
        ]
        
        guard let compressedData = bitmap.representation(using: .jpeg, properties: properties) else {
            isCompressing = false
            return
        }
        
        do {
            try compressedData.write(to: URL(fileURLWithPath: outputPath))
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int) ?? 0
            DispatchQueue.main.async {
                outputSize = String(format: "%.2f KB", Double(fileSize) / 1024.0)
                isCompressing = false
            }
        } catch {
            DispatchQueue.main.async {
                outputSize = "保存失败"
                isCompressing = false
            }
        }
    }
}

#Preview {
    ContentView()
}
