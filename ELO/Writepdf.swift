//
//  Writepdf.swift
//  ELO
//
//  Created by Niels Taatgen on 07/01/2026.
//

import SwiftUI
import CoreGraphics

@MainActor func writePDF<V: View>(
    of view: V
) throws {
    // 1. Get Desktop directory URL
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    
    // 2. Create date + time string
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = formatter.string(from: Date())
    
    // 3. Build filename
    let filename = "ELO_output_\(timestamp).pdf"
    
    // 4. Create full file URL
    let url = desktopURL.appendingPathComponent(filename)
    
//    let a4Size = CGSize(width: 595, height: 842)
    let a4Size = CGSize(width: 842, height: 595) // Landscape

    let renderer = ImageRenderer(
        content: view
            .frame(width: a4Size.width, height: a4Size.height)
    )
    
    renderer.scale = 1.0  // Important: avoid raster scaling
    
    guard let consumer = CGDataConsumer(url: url as CFURL) else {
        throw NSError(domain: "PDFExport", code: 1)
    }
    
    var mediaBox = CGRect(origin: .zero, size: a4Size)
    
    guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "PDFExport", code: 2)
    }
    
    context.beginPDFPage(nil)
    
    renderer.render { size, renderContext in
        renderContext(context)
    }
    
    context.endPDFPage()
    context.closePDF()
}
