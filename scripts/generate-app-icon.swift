#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets", isDirectory: true)
let buildIconset = root.appendingPathComponent(".build/AppIcon.iconset", isDirectory: true)
let previewURL = assets.appendingPathComponent("AppIcon-1024.png")
let icnsURL = assets.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: buildIconset)
try FileManager.default.createDirectory(at: buildIconset, withIntermediateDirectories: true)

func color(_ hex: UInt, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func line(from start: CGPoint, to end: CGPoint, width: CGFloat, color: NSColor, cap: NSBezierPath.LineCapStyle = .round) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = width
    path.lineCapStyle = cap
    color.setStroke()
    path.stroke()
}

func drawIcon(size: CGFloat) -> NSImage {
    let scale = size / 1024
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    color(0x003c33).setFill()
    bounds.fill()

    let darkBand = CGRect(x: 0, y: 0, width: size, height: 338 * scale)
    color(0x17171c).setFill()
    darkBand.fill()

    let card = CGRect(x: 168 * scale, y: 178 * scale, width: 688 * scale, height: 668 * scale)
    color(0xeeece7).setFill()
    roundedRect(card, radius: 84 * scale).fill()

    let inner = card.insetBy(dx: 54 * scale, dy: 58 * scale)
    color(0xffffff).setFill()
    roundedRect(inner, radius: 44 * scale).fill()

    color(0xd9d9dd).setStroke()
    let border = roundedRect(inner, radius: 44 * scale)
    border.lineWidth = 3 * scale
    border.stroke()

    let headerY = inner.maxY - 138 * scale
    line(
        from: CGPoint(x: inner.minX + 58 * scale, y: headerY),
        to: CGPoint(x: inner.maxX - 58 * scale, y: headerY),
        width: 3 * scale,
        color: color(0xd9d9dd),
        cap: .butt
    )

    for index in 0..<3 {
        let x = inner.minX + CGFloat(94 + index * 82) * scale
        color(index == 0 ? 0xff7759 : 0x93939f).setFill()
        NSBezierPath(ovalIn: CGRect(x: x, y: inner.maxY - 92 * scale, width: 28 * scale, height: 28 * scale)).fill()
    }

    let checkBox = CGRect(x: inner.minX + 72 * scale, y: inner.minY + 316 * scale, width: 146 * scale, height: 146 * scale)
    color(0x003c33).setFill()
    roundedRect(checkBox, radius: 34 * scale).fill()
    line(
        from: CGPoint(x: checkBox.minX + 34 * scale, y: checkBox.midY - 4 * scale),
        to: CGPoint(x: checkBox.minX + 63 * scale, y: checkBox.midY - 32 * scale),
        width: 17 * scale,
        color: color(0xffffff)
    )
    line(
        from: CGPoint(x: checkBox.minX + 63 * scale, y: checkBox.midY - 32 * scale),
        to: CGPoint(x: checkBox.maxX - 29 * scale, y: checkBox.midY + 42 * scale),
        width: 17 * scale,
        color: color(0xffffff)
    )

    let textX = checkBox.maxX + 46 * scale
    let textTop = checkBox.maxY - 20 * scale
    line(from: CGPoint(x: textX, y: textTop), to: CGPoint(x: inner.maxX - 80 * scale, y: textTop), width: 24 * scale, color: color(0x212121), cap: .round)
    line(from: CGPoint(x: textX, y: textTop - 58 * scale), to: CGPoint(x: inner.maxX - 172 * scale, y: textTop - 58 * scale), width: 18 * scale, color: color(0x75758a), cap: .round)

    let routineY = inner.minY + 164 * scale
    let dotColors: [UInt] = [0xedfce9, 0xf1f5ff, 0xffad9b, 0xedfce9, 0xf1f5ff]
    for index in 0..<5 {
        let x = inner.minX + CGFloat(78 + index * 104) * scale
        let rect = CGRect(x: x, y: routineY, width: 58 * scale, height: 58 * scale)
        color(dotColors[index]).setFill()
        roundedRect(rect, radius: 18 * scale).fill()
        color(index == 2 ? 0xff7759 : 0x003c33).setStroke()
        let path = roundedRect(rect, radius: 18 * scale)
        path.lineWidth = 3 * scale
        path.stroke()
    }

    let vPath = NSBezierPath()
    vPath.move(to: CGPoint(x: 338 * scale, y: 736 * scale))
    vPath.line(to: CGPoint(x: 496 * scale, y: 586 * scale))
    vPath.line(to: CGPoint(x: 684 * scale, y: 746 * scale))
    vPath.lineWidth = 36 * scale
    vPath.lineCapStyle = .round
    vPath.lineJoinStyle = .round
    color(0x17171c).setStroke()
    vPath.stroke()

    image.unlockFocus()
    return image
}

func pngData(for image: NSImage, size: Int) -> Data {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not create PNG data for \(size)")
    }
    return data
}

let iconSizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

let preview = drawIcon(size: 1024)
try pngData(for: preview, size: 1024).write(to: previewURL)

for icon in iconSizes {
    let pixelSize = icon.points * icon.scale
    let image = drawIcon(size: CGFloat(pixelSize))
    let url = buildIconset.appendingPathComponent(icon.name)
    try pngData(for: image, size: pixelSize).write(to: url)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", buildIconset.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    fatalError("iconutil failed with status \(process.terminationStatus)")
}

print("Generated \(previewURL.path)")
print("Generated \(icnsURL.path)")
