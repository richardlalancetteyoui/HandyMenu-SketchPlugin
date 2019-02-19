//
//  DataProvider.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 10/06/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

public protocol DataControllerDelegate: class {
    
    func dataController(_ dataController: DataController,
                        didUpdate data: PluginData)
    
    func dataController(_ dataController: DataController,
                        didLoad installedPlugins: [InstalledPluginData])
    
}

public class DataController {
    
    // MARK: - Singleton
    public static var shared = DataController()
    
    // MARK: - Private Properties
    private var sketchCommands: [String]
    private var dataCaretaker: DataCaretaker
    
    // MARK: - Public Properties
    public var pluginData: PluginData?
    public var installedPlugins: [InstalledPluginData]
    public var usedShortcuts: Set<Int> {
        if let shortcutHashes = pluginData?.collections.compactMap({$0.shortcut.hashValue}) {
            return Set(shortcutHashes)
        }
        return []
    }
    
    // MARK: - Public Properties
    public weak var delegate: DataControllerDelegate?
    
    // MARK: - Lifecycle
    public init() {
        self.installedPlugins = []
        self.sketchCommands = []
        self.dataCaretaker = DataCaretaker()
    }

    // MARK: - Instance Methods
    public func load() {
        self.loadPluginData()
        self.loadInstalledPlugins()
        self.loadSketchCommands()
    }
    
    private func filterCollections() {
        guard let pluginData = self.pluginData else { return }
        
        var filteredCollections: [Collection] = [] // Preparing new array for filtered collections
        for unfilteredCollection in pluginData.collections {
            var newCollection = unfilteredCollection
            newCollection.items = unfilteredCollection.items.filter({(collectionItem) -> Bool in
                switch collectionItem {
                case .separator:
                    return true
                case .command(let commandData):
                    return SketchAppBridge.sharedInstance().isExists(commandData.pluginID, with: commandData.commandID)
                case .sketchCommand(let sketchCommand):
                    // TODO
                    return true
                }
            })
            filteredCollections.append(newCollection)
        }
        self.pluginData?.collections = filteredCollections
    }
    
    public func saveCollections(_ collections: [Collection]) {
        self.pluginData?.collections = collections
        guard let pluginData = self.pluginData,
            self.dataCaretaker.save(pluginData) else { return }
        self.delegate?.dataController(self, didUpdate: pluginData)
    }
    
    private func loadPluginData() {
        self.pluginData = dataCaretaker.retrieve() ?? PluginData.empty
        self.pluginData?.pluginVersion = PluginData.currentVersion
        self.filterCollections()
        delegate?.dataController(self, didUpdate: pluginData!)
    }
    
    private func loadInstalledPlugins() {
        
        guard
            let installedPlugins = SketchAppBridge.sharedInstance().installedPlugins as? [String: NSObject]
            else { return }
        
        var installedPluginsData: [InstalledPluginData] = []
        
        for (pluginKey, pluginBundle) in installedPlugins {
            // Checking if the plugin exists and has name
            guard let pluginName = pluginBundle.value(forKey: "name") as? String,
                pluginName != "Handy Menu" else { continue }
            let pluginImage: NSImage? = pluginBundle.value(forKeyPath: "iconInfo.image") as? NSImage
            var installedPluginData = InstalledPluginData(pluginName: pluginName, image: pluginImage, commands: [])
            
            // Checking if the plugin has commands
            guard
                let commandsDictionary = pluginBundle.value(forKey: "commands") as? [String: NSObject]
                else { continue }
            
            for (_, commandBundle) in commandsDictionary {
                // Command should have name, identifier and run handler
                if let hasRunHandler = commandBundle.value(forKey: "hasRunHandler") as? Bool, hasRunHandler == true,
                    let commandName = commandBundle.value(forKey: "name") as? String,
                    let commandID = commandBundle.value(forKey: "identifier") as? String {
                    
                    let installedPluginCommand = PluginCommand(name: commandName,
                                                               commandID: commandID,
                                                               pluginName: pluginName,
                                                               pluginID: pluginKey)
                    
                    installedPluginData.commands.append(installedPluginCommand)
                }
            }
            installedPluginsData.append(installedPluginData)
        }
        self.installedPlugins = installedPluginsData
        installedPluginsData.sort { $0.pluginName < $1.pluginName }
        self.delegate?.dataController(self, didLoad: installedPluginsData)
    }
    
    private func loadSketchCommands() {
        guard let mainMenu = NSApplication.shared.mainMenu else { return }
        let menuItems = mainMenu.items.compactMap { $0.title }
        plugin_log("%@", String(describing: menuItems))
    }
}
