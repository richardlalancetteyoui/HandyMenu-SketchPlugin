//
//  SettingsWindowController+NSCollectionViewDelegateFlowLayout.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 30/09/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

// MARK: - NSCollectionViewDelegate
extension SettingsWindowController: NSCollectionViewDelegateFlowLayout {
    
    // Configuring Items, Headers and Footers sizes
    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.bounds.width, height: self.commandHeight)
    }
    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: collectionView.bounds.width, height: self.headerHeight)
    }
    
    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> NSSize {
        return NSSize(width: collectionView.bounds.width, height: self.footerHeight)
    }
    
    // Enable Dragging
    public func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
        return true
    }
    
    // Selections And Deselection
    public func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        guard let indexPath = indexPaths.first,
            let item = self.installedPluginsCollectionView.item(at: indexPath) as? CommandCollectionViewItem,
            !item.isUsed else { return [] }
        return indexPaths
    }
    
    public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first,
            let item = collectionView.item(at: indexPath) as? CommandCollectionViewItem else { return }
        item.setHighlight(true)
    }
    
    public func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first,
            let item = collectionView.item(at: indexPath) as? CommandCollectionViewItem else { return }
        item.setHighlight(false)
    }
    
    // Drag & Drop
    // Writing dragging item's indexPath to pasteboard
    public func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
        guard let indexPath = indexPaths.first,
            let item = self.installedPluginsCollectionView.item(at: indexPath) as? CommandCollectionViewItem,
            !item.isUsed else { return false }
        let data = NSKeyedArchiver.archivedData(withRootObject: indexPath)
        pasteboard.declareTypes([.string], owner: self)
        pasteboard.setData(data, forType: .string)
        return true
    }
    
    // Preventing animation when cancel dragging
    public func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexes: IndexSet) {
        session.animatesToStartingPositionsOnCancelOrFail = false
    }
}
