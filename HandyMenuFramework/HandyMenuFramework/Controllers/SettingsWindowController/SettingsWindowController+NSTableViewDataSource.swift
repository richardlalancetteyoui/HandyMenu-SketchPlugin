//
//  SettingsWindowController+NSTableViewDataSource.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 30/09/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

// MARK: - NSTableViewDataSource
extension SettingsWindowController: NSTableViewDataSource {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return self.collections[currentCollectionIndex].items.count
    }
    
}
