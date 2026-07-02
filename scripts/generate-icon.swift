#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icon = resources.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in entries {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    drawIcon(size: CGFloat(size))
    image.unlockFocus()
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "Icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to render \(name)"])
    }
    try png.write(to: iconset.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icon.path]
try process.run()
process.waitUntilExit()
if process.terminationStatus != 0 {
    throw NSError(domain: "Icon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

func drawIcon(size: CGFloat) {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let corner = size * 0.22
    let shape = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), xRadius: corner, yRadius: corner)

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()

    let gradient = NSGradient(colors: [
        NSColor(red: 0.03, green: 0.05, blue: 0.10, alpha: 1),
        NSColor(red: 0.04, green: 0.14, blue: 0.18, alpha: 1),
        NSColor(red: 0.11, green: 0.08, blue: 0.22, alpha: 1),
    ])!
    gradient.draw(in: rect, angle: 315)

    let line = NSBezierPath()
    line.lineCapStyle = .round
    line.lineJoinStyle = .round
    line.lineWidth = size * 0.045
    line.move(to: point(0.25, 0.34, size))
    line.line(to: point(0.47, 0.64, size))
    line.line(to: point(0.76, 0.42, size))
    line.move(to: point(0.47, 0.64, size))
    line.line(to: point(0.62, 0.78, size))
    NSColor(red: 0.24, green: 0.72, blue: 1.0, alpha: 0.88).setStroke()
    line.stroke()

    let softLine = NSBezierPath()
    softLine.lineCapStyle = .round
    softLine.lineJoinStyle = .round
    softLine.lineWidth = size * 0.030
    softLine.move(to: point(0.25, 0.34, size))
    softLine.curve(to: point(0.76, 0.42, size), controlPoint1: point(0.30, 0.82, size), controlPoint2: point(0.74, 0.80, size))
    NSColor(red: 0.43, green: 1.0, blue: 0.72, alpha: 0.78).setStroke()
    softLine.stroke()

    drawNode(x: 0.25, y: 0.34, size: size, radius: 0.075, color: NSColor(red: 0.43, green: 1.0, blue: 0.72, alpha: 1))
    drawNode(x: 0.47, y: 0.64, size: size, radius: 0.088, color: NSColor.white)
    drawNode(x: 0.76, y: 0.42, size: size, radius: 0.075, color: NSColor(red: 0.28, green: 0.70, blue: 1.0, alpha: 1))
    drawNode(x: 0.62, y: 0.78, size: size, radius: 0.050, color: NSColor(red: 0.72, green: 0.64, blue: 1.0, alpha: 1))

    NSGraphicsContext.restoreGraphicsState()
}

func point(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat) -> CGPoint {
    CGPoint(x: size * x, y: size * y)
}

func drawNode(x: CGFloat, y: CGFloat, size: CGFloat, radius radiusRatio: CGFloat, color: NSColor) {
    let radius = size * radiusRatio
    let rect = CGRect(x: size * x - radius, y: size * y - radius, width: radius * 2, height: radius * 2)
    color.withAlphaComponent(0.24).setFill()
    NSBezierPath(ovalIn: rect.insetBy(dx: -radius * 0.55, dy: -radius * 0.55)).fill()
    color.setFill()
    NSBezierPath(ovalIn: rect).fill()
}
