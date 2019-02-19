//
//  HMPluginController.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 10/06/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//
@objc(HandyMenuPlugin) class PluginController: NSObject {
    
    // MARK: - Singletone instance
    @objc static let shared = PluginController()
    private override init() { }
    
    // MARK: - Private Properties
    private let settingsWindowController = SettingsWindowController(windowNibName: .settingsWindowController)
    private let shortcutController = ShortcutController()
    
    // MARK: - Plugin Lifecycle
    @objc public func configure() {
        settingsWindowController.delegate = self
        shortcutController.delegate = self
        
        DataController.shared.delegate = self
        DataController.shared.load()
    }
    
    @objc public func showSettings() {
        settingsWindowController.showWindow(nil)
        shortcutController.stop()
    }
    
    @objc public func show(_ collection: String) {
        showSettings()
        settingsWindowController.showCollection(collection)
    }
    
}

// MARK: - PluginDataControllerDelegate
extension PluginController: DataControllerDelegate {
    
    func dataController(_ dataController: DataController, didUpdate data: PluginData) {
        shortcutController.start()
        MenuController.shared.configure(for: data.collections)
        settingsWindowController.configure(data.collections)
    }
    
    func dataController(_ dataController: DataController, didLoad installedPlugins: [InstalledPluginData]) {
        self.settingsWindowController.installedPlugins = installedPlugins
    }
}

// MARK: - ShortcutControllerDelegate
extension PluginController: ShortcutControllerDelegate {
    
    func shortcutController(_ shortcutController: ShortcutController,
                            didRecognize shortcut: Shortcut,
                            in event: NSEvent) -> NSEvent? {
        
        guard !NSDocumentController.shared.documents.isEmpty,
            DataController.shared.usedShortcuts.contains(shortcut.hashValue)
            else { return event }
        MenuController.shared.show(for: shortcut)
        return nil
    }
    
}

// MARK: - SettingsWindowControllerDelegate
extension PluginController: SettingsWindowControllerDelegate {
    
    func settingsWindowController(_ settingsWindowController: SettingsWindowController,
                                  didUpdate menuData: [Collection]) {
        DataController.shared.saveCollections(menuData)
    }
    
    func settingsWindowControllerDidClose(_ settingsWindowController: SettingsWindowController) {
        shortcutController.start()
    }
    
}
