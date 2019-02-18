//
//  NSImage.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 05/08/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

extension NSImage.Name {
    static let settingsIcon = NSImage.Name("icon_settings")
    static let searchIcon = NSImage.Name("icon_search")
    static let returnIcon = NSImage.Name("icon_return")
    static let pluginIconPlaceholderImage = NSImage.Name("image_placeholder")
}

extension NSImage {
    static let pluginIconPlaceholderImage = Bundle.pluginBundle.image(forResource: .pluginIconPlaceholderImage)
    static let searchIconImage = Bundle.pluginBundle.image(forResource: .searchIcon)
    static let returnIconImage = Bundle.pluginBundle.image(forResource: .returnIcon)
    
    func tinted(by color: NSColor) -> NSImage {
        self.isTemplate = false
        guard let image = self.copy() as? NSImage
            else { return self }
        
        image.lockFocus()
        
        color.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        
        image.unlockFocus()
        image.isTemplate = false
        
        return image
    }
}
