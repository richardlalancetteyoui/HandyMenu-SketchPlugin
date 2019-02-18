//
//  SettingsWindowController+CollectionTableViewDelegate.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 30/09/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

// MARK: - CollectionTableViewDelegate
extension SettingsWindowController: CollectionTableViewDelegate {
    
    // Changing cursor when dragging out of tableView
    func collectionTableView(_ collectionTableView: CollectionTableView,
                             draggingSession session: NSDraggingSession,
                             movedTo screenPoint: NSPoint) {
        
        if let tableViewRect = self.window?.convertToScreen(self.collectionTableViewRect),
            !tableViewRect.contains(screenPoint) {
            NSCursor.disappearingItem.set()
        } else {
            NSCursor.arrow.set()
        }
    }
    
    // Deleting item if DEL key is pressed (CollectionTableViewDelegate)
    func deleteIsPressed(at rows: IndexSet) {
        guard let index = rows.first else { return }
        self.removeCommand(at: index)
    }
    
}
