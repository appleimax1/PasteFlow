import Cocoa

extension NSImage {
    func generateThumbnailData(maxSize: CGFloat = 200.0, compression: Float = 0.7) -> Data? {
        var imageRect = CGRect(origin: .zero, size: self.size)
        guard let cgImage = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let ratio = max(width / maxSize, height / maxSize)
        if ratio <= 1.0 {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: compression)])
        }
        
        let newSize = NSSize(width: width / ratio, height: height / ratio)
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        guard let tiff = newImage.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: compression)])
    }
}
