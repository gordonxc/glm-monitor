import SwiftUI

@main
struct GLMMonitorApp: App {
    @StateObject private var viewModel = MonitorViewModel()

    var sessionPercentage: Int? {
        viewModel.sessionLimit?.percentage
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            if viewModel.statusBarMode == .pie, let pct = sessionPercentage {
                Image(nsImage: combinedPieImage(percentage: pct))
            } else {
                HStack(spacing: 4) {
                    Image(nsImage: loadAppIcon())
                    Text(sessionPercentage.map { "\($0)%" } ?? "—")
                }
            }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
                .keyboardShortcut("r")
            }
        }
    }

    private func loadAppIcon() -> NSImage {
        let iconPath = Bundle.main.resourcePath.map { $0 + "/AppIcon.png" } ?? ""
        if let img = NSImage(contentsOfFile: iconPath) {
            img.size = NSSize(width: 16, height: 16)
            return img
        }
        return NSImage(systemSymbolName: "gauge.with.dots.needle.33percent",
                       accessibilityDescription: "GLM")!
    }

    private func combinedPieImage(percentage: Int) -> NSImage {
        let side: Int = 44 // icon(20) + gap(4) + pie(20)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            .union(.byteOrder32Little)

        guard let cgCtx = CGContext(
            data: nil, width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side * 4,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return loadAppIcon() }

        // Draw app icon on the left
        let icon = loadAppIcon()
        if let cgIcon = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            cgCtx.draw(cgIcon, in: CGRect(x: 2, y: 2, width: 18, height: 18))
        }

        // Draw pie chart on the right
        let pieCenter = CGPoint(x: 33, y: CGFloat(side) / 2)
        let radius: CGFloat = 9
        let pieRect = CGRect(x: pieCenter.x - radius, y: pieCenter.y - radius, width: radius * 2, height: radius * 2)

        // Background circle
        cgCtx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.3))
        cgCtx.fillEllipse(in: pieRect)

        // Filled arc
        let fraction = CGFloat(percentage) / 100.0
        if fraction > 0 {
            let color: CGColor
            if percentage > 90 { color = CGColor(red: 1, green: 0.3, blue: 0.3, alpha: 1) }
            else if percentage > 70 { color = CGColor(red: 1, green: 0.6, blue: 0.2, alpha: 1) }
            else { color = CGColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1) }

            cgCtx.setFillColor(color)
            cgCtx.move(to: pieCenter)
            cgCtx.addArc(center: pieCenter, radius: radius,
                         startAngle: .pi / 2,
                         endAngle: .pi / 2 - fraction * 2 * .pi,
                         clockwise: true)
            cgCtx.closePath()
            cgCtx.fillPath()
        }

        // Outline
        cgCtx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        cgCtx.setLineWidth(1.5)
        cgCtx.strokeEllipse(in: pieRect)

        guard let cgImage = cgCtx.makeImage() else { return loadAppIcon() }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: 22, height: 22))
        image.isTemplate = false
        return image
    }
}
