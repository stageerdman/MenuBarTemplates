#!/usr/bin/env bash
# Regenerate the app icon (Resources/AppIcon.icns) from an SF Symbol.
# White rounded-rect (squircle) background with a copy/paste glyph, so the app
# is easy to spot in the Dock. Edit SYMBOL / GLYPH color below to tweak.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES_DIR="$ROOT_DIR/Resources"
WORK_DIR="$(mktemp -d)"
ICONSET="$WORK_DIR/AppIcon.iconset"
mkdir -p "$ICONSET" "$RES_DIR"

SWIFT_SRC="$WORK_DIR/render.swift"
cat > "$SWIFT_SRC" <<'SWIFT'
import AppKit
import Foundation

let outDir = CommandLine.arguments[1]

// --- Icon design knobs ---------------------------------------------------
let symbolName = "doc.on.clipboard"          // copy/paste glyph
let glyph = NSColor(srgbRed: 0.13, green: 0.16, blue: 0.20, alpha: 1) // near-black slate
let bg = NSColor.white                         // white background, as requested
let bgPadFrac: CGFloat = 0.06                  // transparent margin around squircle
let cornerFrac: CGFloat = 0.2237               // Apple squircle radius ratio
let glyphFrac: CGFloat = 0.54                  // glyph size vs. squircle
// ------------------------------------------------------------------------

func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    image.draw(at: .zero, from: NSRect(origin: .zero, size: image.size),
               operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.compositingOperation = .sourceAtop
    color.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: image.size)).fill()
    out.unlockFocus()
    return out
}

func makePNG(_ size: Int) -> Data? {
    let s = CGFloat(size)
    let canvas = NSImage(size: NSSize(width: s, height: s))
    canvas.lockFocus()

    let pad = s * bgPadFrac
    let rect = NSRect(x: pad, y: pad, width: s - 2 * pad, height: s - 2 * pad)
    let radius = rect.width * cornerFrac
    bg.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.5, weight: .semibold)
    if let raw = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let sym = tinted(raw, glyph)
        let target = rect.width * glyphFrac
        let scale = target / max(sym.size.width, sym.size.height)
        let dw = sym.size.width * scale
        let dh = sym.size.height * scale
        sym.draw(in: NSRect(x: (s - dw) / 2, y: (s - dh) / 2, width: dw, height: dh))
    }

    canvas.unlockFocus()
    guard let tiff = canvas.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    return rep.representation(using: .png, properties: [:])
}

// iconset members: (pixel size, filename)
let members: [(Int, String)] = [
    (16, "icon_16x16.png"),   (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),   (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),(256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),(512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),(1024, "icon_512x512@2x.png"),
]

for (px, name) in members {
    guard let data = makePNG(px) else { fputs("failed \(name)\n", stderr); exit(1) }
    try data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
}
print("rendered \(members.count) pngs")
SWIFT

swift "$SWIFT_SRC" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$RES_DIR/AppIcon.icns"
rm -rf "$WORK_DIR"
echo "Wrote $RES_DIR/AppIcon.icns"
