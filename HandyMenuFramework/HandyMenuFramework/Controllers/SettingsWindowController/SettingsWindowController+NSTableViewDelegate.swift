//
//  SettingsWindowController+NSTableViewDelegate.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 30/09/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

// MARK: - NSTableViewDelegate
extension SettingsWindowController: NSTableViewDelegate {
    
    // Setting Height For Item
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return self.commandHeight
    }
    
    // Cofiguring Item's View
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = collections[currentCollectionIndex].items[row]
        switch item {
        case .command(let commandData):
            guard let commandCell = currentCollectionTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommandCell"), owner: self) as? CommandTableViewItem else { return nil }
            commandCell.title = commandData.name
            commandCell.toolTip = commandData.pluginName
            return commandCell
        case .separator:
            guard let separatorCell = currentCollectionTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SeparatorCell"), owner: self) else { return nil }
            return separatorCell
        }
    }
    
    // Handling Selection
    public func tableViewSelectionDidChange(_ notification: Notification) {
        self.deleteItemButton.isEnabled = self.currentCollectionTableView.selectedRowIndexes.count != 0
    }
    
    // Drag And Drop
    public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return NSDragOperation.link
    }
    
    // Writing moving item index into pasteboard at the begining of the drag
    public func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        self.currentCollectionTableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([.string], owner: self)
        pboard.setData(data, forType: .string)
        return true
    }
    
    // Handling Drop
    public func insertNewCommand(from indexPath: IndexPath, to row: Int) {
        let pluginCommandData = self.pluginCommandAtIndexPath(indexPath)
        let newCommand = CollectionItem.command(pluginCommandData)
        self.currentCollection.items.insert(newCommand, at: row)
        self.currentCollectionTableView.insertRows(at: IndexSet(integer: row), withAnimation: .effectFade)
        self.installedPluginsCollectionView.reloadItems(at: [indexPath])
    }
    
    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let data = info.draggingPasteboard().data(forType: .string) else { return false }
        
        if self.installedPluginsCollectionView.isEqual(info.draggingSource())  {
            guard let sourceIndexPath = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? IndexPath else { return false }
            self.insertNewCommand(from: sourceIndexPath, to: row)
            return true
        } else if self.currentCollectionTableView.isEqual(info.draggingSource()) {
            guard let indexes = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? IndexSet,
                let fromRow = indexes.first else { return false }
            let toRow = (fromRow > row) ? row : row - 1
            let movingItem = self.currentCollection.items.remove(at: fromRow)
            self.currentCollection.items.insert(movingItem, at: toRow)
            self.currentCollectionTableView.moveRow(at: fromRow, to: toRow)
            self.currentCollectionTableView.deselectAll(nil)
            return true
        }
        
        return false
    }
    
    // Preventing animation after deleting
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        session.animatesToStartingPositionsOnCancelOrFail = false
    }
    
    // Deleting item if drop was outside tableView
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if  let tableViewRect = self.window?.convertToScreen(self.collectionTableViewRect),
            !tableViewRect.contains(screenPoint),
            let data = session.draggingPasteboard.data(forType: .string),
            let indexes = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? IndexSet,
            let rowToDelete = indexes.first {
            self.removeCommand(at: rowToDelete)
        }
    }
    

    
}
