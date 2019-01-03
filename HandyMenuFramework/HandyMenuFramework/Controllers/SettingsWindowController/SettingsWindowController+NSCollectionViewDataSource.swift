//
//  SettingsWindowController+NSCollectionViewDataSource.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 30/09/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

// MARK: - NSCollectionViewDataSource
extension SettingsWindowController: NSCollectionViewDataSource {
    
    // Common DataSource Methods
    public func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return self.filteredPlugins.count
    }
    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredPlugins[section].commands.count
    }
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let collectionViewItem = self.installedPluginsCollectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommandCollectionViewItem"), for: indexPath) as? CommandCollectionViewItem else { return NSCollectionViewItem()}
        let commandData = self.pluginCommandAtIndexPath(indexPath)
        collectionViewItem.configure(commandData.name, isUsed: self.currentCollection.items.contains(.command(commandData)))
        collectionViewItem.searchingString = self.searchField.stringValue
        collectionViewItem.delegate = self
        return collectionViewItem
    }
    
    // Configuring Views For Headers And Footers
    public func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        switch kind {
        case NSCollectionView.elementKindSectionHeader:
            let suppementaryHeaderView = self.installedPluginsCollectionView.makeSupplementaryView(ofKind: kind,
                                                                                                   withIdentifier: NSUserInterfaceItemIdentifier("PluginSectionHeaderView"),
                                                                                                   for: indexPath) as! PluginSectionHeaderView
            suppementaryHeaderView.title = self.filteredPlugins[indexPath.section].pluginName
            suppementaryHeaderView.image = self.filteredPlugins[indexPath.section].image ?? NSImage.pluginIconPlaceholderImage
            suppementaryHeaderView.searchingString = self.searchField.stringValue
            return suppementaryHeaderView
        case NSCollectionView.elementKindSectionFooter:
            return self.installedPluginsCollectionView.makeSupplementaryView(ofKind: kind,
                                                                             withIdentifier: NSUserInterfaceItemIdentifier("PluginSectionFooterView"),
                                                                             for: indexPath)
        default:
            return NSView()
        }
    }
    
}
