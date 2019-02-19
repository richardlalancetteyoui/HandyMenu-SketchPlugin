//
//  SettingsWindowController.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 18/07/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

public protocol SettingsWindowControllerDelegate: class {
    
    func settingsWindowController(_ settingsWindowController: SettingsWindowController,
                                  didUpdate menuData: [Collection])
    
    func settingsWindowControllerDidClose(_ settingsWindowController: SettingsWindowController)
}

public class SettingsWindowController: NSWindowController, SettingsWindowViewControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var noPluginsLabel: NSTextField! {
        didSet {
            noPluginsLabel.alphaValue = 0.0
        }
    }
    @IBOutlet private weak var emptyListLabel: NSTextField! {
        didSet {
            emptyListLabel.alphaValue = 0.0
        }
    }
    @IBOutlet weak var collectionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var collectionSettingsMenu: NSMenu!
    @IBOutlet weak var removeMenuItem: NSMenuItem!
    @IBOutlet weak var shortcutField: ShortcutField!
    @IBOutlet weak var insertSeparatorButton: NSButton!
    @IBOutlet weak var autoGroupingCheckboxButton: NSButton!
    @IBOutlet weak var collectionsScrollView: NSScrollView!
    @IBOutlet weak var renamingPanel: InputPanel!
    @IBOutlet weak var searchField: SearchField!
    @IBOutlet weak var installedPluginsCollectionView: NSCollectionView!
    @IBOutlet weak var deleteItemButton: NSButton!
    @IBOutlet weak var currentCollectionTableView: NSTableView!
    
    // MARK: - Private Properties
    let windowViewController = SettingsWindowViewController()
    
    var currentCollectionIndex: Int = 0
    var collections: [Collection] = []
    
    var filteredPlugins: [InstalledPluginData] = [] {
        didSet {
            toggleNoPluginsLabel()
        }
    }
    
    var currentCollection: Collection {
        get {
            return collections[currentCollectionIndex]
        }
        set {
            collections[currentCollectionIndex] = newValue
            toggleEmptyLabel()
        }
    }
    
    let commandHeight: CGFloat = 24.0
    let headerHeight: CGFloat = 48.0
    let footerHeight: CGFloat = 32.0
    
    public var collectionTableViewRect: NSRect {
        let rect = currentCollectionTableView.convert(collectionsScrollView.bounds, to: nil)
        return rect.insetBy(dx: -10, dy: -20)
    }
    
    // MARK: - Public Properties
    public weak var delegate: SettingsWindowControllerDelegate?
    public var installedPlugins: [InstalledPluginData] = []
    
    // MARK: - Instance Lifecycle
    override public func windowDidLoad() {
        super.windowDidLoad()
        
        installedPluginsCollectionView.delegate = self
        installedPluginsCollectionView.dataSource = self
        installedPluginsCollectionView.registerForDraggedTypes([.string])
        installedPluginsCollectionView.setDraggingSourceOperationMask(.link, forLocal: false)
        
        currentCollectionTableView.delegate = self
        currentCollectionTableView.dataSource = self
        currentCollectionTableView.reloadData()
        currentCollectionTableView.registerForDraggedTypes([.string])
        currentCollectionTableView.setDraggingSourceOperationMask(.move, forLocal: true)
        
        // Fixing the first column width
        currentCollectionTableView.sizeToFit()
        
        windowViewController.delegate = self
        windowViewController.view = window!.contentView!
        window?.contentViewController = windowViewController
        
        shortcutField.delegate = self
        
        searchField.delegate = self
        
        configure(collections)
    }
    
    public override func close() {
        super.close()
        window?.makeFirstResponder(nil)
        shortcutField.finish(with: nil)
        delegate?.settingsWindowControllerDidClose(self)
    }
    
    // Refreshing collectionView layout after resizing window (SettingsWindowViewControllerDelegate)
    public func viewWillLayout() {
        installedPluginsCollectionView.collectionViewLayout?.invalidateLayout()
    }
    
    // Reseting selection if click on empty space
    public override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(nil)
        installedPluginsCollectionView.deselectAll(nil)
        currentCollectionTableView.deselectAll(nil)
        shortcutField.finish(with: nil)
        super.mouseDown(with: event)
    }
    
    // Public Methods
    public func showCollection(_ collection: String) {
        selectCollection(at: collectionsPopUpButton.indexOfItem(withTitle: collection))
    }
    
    public func configure(_ collections: [Collection]) {
        self.collections = collections
        
        if self.collections.isEmpty {
            self.collections.append(.emptyCollection)
        }
        
        if isWindowLoaded {
            currentCollectionTableView.reloadData()
            configureCollectionsPopUpButton()
            selectCollection(at: collections.startIndex)
            filterInstalledPlugins(by: "")
            versionLabel.stringValue = "Version \(PluginData.currentVersion)"
        }
    }
    
    // Private Methods
    private func configureCollectionsPopUpButton() {
        collectionsPopUpButton.removeAllItems()
        collectionsPopUpButton.addItems(withTitles: collections.map({$0.title}))
    }
    
    private func configureAutoGrouping(for autoGroupingOn: Bool) {
        currentCollection.autoGrouping = autoGroupingOn
        insertSeparatorButton.isEnabled = !autoGroupingOn
        autoGroupingCheckboxButton.state = autoGroupingOn ? .on : .off
        
        if autoGroupingOn, currentCollection.items.contains(.separator) {
            var separatorIndexes: IndexSet = []
            for (index, item) in currentCollection.items.enumerated() {
                if case CollectionItem.separator = item {
                    separatorIndexes.insert(index)
                }
            }
            currentCollection.items = currentCollection.items.filter { $0 != .separator }
            plugin_log("Filtered array: %@", String(describing: currentCollection.items))
            currentCollectionTableView.removeRows(at: separatorIndexes, withAnimation: .effectFade)
        }
    }
    
    private func toggleEmptyLabel() {
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.duration = 0.2
            emptyListLabel.animator().alphaValue = currentCollection.items.isEmpty ? 1.0 : 0.0
        })
    }
    
    private func toggleNoPluginsLabel() {
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.duration = 0.2
            noPluginsLabel.animator().alphaValue = filteredPlugins.isEmpty ? 1.0 : 0.0
        })
    }
    
    private func selectCollection(at index: Int) {
        currentCollectionIndex = index
        collectionsPopUpButton.selectItem(at: index)
        installedPluginsCollectionView.reloadData()
        currentCollectionTableView.reloadData()
        shortcutField.shortcut = currentCollection.shortcut
        configureAutoGrouping(for: currentCollection.autoGrouping)
    }
    
    private func uniqueCollectionTitle() -> String {
        var newTitle = ""
        for freeIndex in 0...collections.endIndex {
            newTitle = "New Collection \(freeIndex + 1)"
            guard collectionsPopUpButton.itemTitles.contains(newTitle) else { break }
        }
        return newTitle
    }
    
    public func pluginCommandAtIndexPath(_ indexPath: IndexPath) -> PluginCommand {
        return filteredPlugins[indexPath.section].commands[indexPath.item]
    }
    
    public func removeCommand(at row: IndexSet.Element) {
        currentCollection.items.remove(at: row)
        currentCollectionTableView.removeRows(at: [row], withAnimation: .effectFade)
        installedPluginsCollectionView.reloadData()
    }
    
    // Filtering installedPlugins
    private func filterInstalledPlugins(by searchString: String) {
        guard !searchString.isEmpty else {
            filteredPlugins = installedPlugins
            installedPluginsCollectionView.reloadData()
            return
        }
        
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.filteredPlugins = self.installedPlugins.filter {
                $0.pluginName.localizedCaseInsensitiveContains(searchString) ||
                $0.commands.contains(where: { $0.name.localizedCaseInsensitiveContains(searchString)})
            }
            DispatchQueue.main.sync { [unowned self] in
                self.installedPluginsCollectionView.reloadData()
                self.installedPluginsCollectionView.scrollToVisible(NSRect.zero)
            }
        }
    }
}

// MARK: - CommandCollectionViewItemDelegate
extension SettingsWindowController: CommandCollectionViewItemDelegate {
    //Handling double click (CommandCollectionViewItemDelegate)
    func doubleClick(on item: CommandCollectionViewItem) {
        guard let sourceIndexPath = installedPluginsCollectionView.indexPath(for: item) else { return }
        insertNewCommand(from: sourceIndexPath, to: currentCollection.items.endIndex)
    }
}

// MARK: - ShortcutFieldDelegate
extension SettingsWindowController: ShortcutFieldDelegate {
    func shortcutField(_ shortcutField: ShortcutField, didChange shortcut: Shortcut) {
        currentCollection.shortcut = shortcut
    }
}

// MARK: - SearchField Delegate {
extension SettingsWindowController: SearchFieldDelegate {
    public func searchField(_ searchField: SearchField, didChanged value: String) {
        filterInstalledPlugins(by: value)
    }
}

// MARK: - Actions Handling
extension SettingsWindowController {
    
    // Managing Selected Collection
    @IBAction func openCollectionSettings(_ sender: Any) {
        removeMenuItem.isEnabled = collections.count > 1 ? true : false
        if let sender = sender as? NSButton {
            let point = NSPoint(x: 0, y: sender.bounds.height)
            collectionSettingsMenu.popUp(positioning: nil, at: point, in: sender)
        }
    }
    
    @IBAction func renameCollection(_ sender: Any) {
        guard let window = window else { return }
        renamingPanel.value = currentCollection.title
        renamingPanel.beginSheet(for: window) { [weak self] _ in
            
            guard let self = self else { return }
            let value = self.renamingPanel.value
            
            guard
                !value.isEmpty,
                let selectedItem = self.collectionsPopUpButton.selectedItem,
                !selectedItem.title.isEqual(value)
                else { return }
            
                let newValue = self.collectionsPopUpButton.itemTitles.contains(value) ? value + " copy" : value
                self.currentCollection.title = newValue
                self.collectionsPopUpButton.selectedItem?.title = newValue
        }
    }
    
    @IBAction func removeCollection(_ sender: Any) {
        collections.remove(at: currentCollectionIndex)
        let lastIndex = collections.index(before: collections.endIndex)
        let newIndex = (currentCollectionIndex > lastIndex) ? lastIndex : currentCollectionIndex
        configureCollectionsPopUpButton()
        selectCollection(at: newIndex)
    }
    
    @IBAction func addNewCollection(_ sender: Any) {
        let newIndex = collections.endIndex
        var newCollection = Collection.emptyCollection
        newCollection.title = uniqueCollectionTitle()
        collections.insert(newCollection, at: newIndex)
        configureCollectionsPopUpButton()
        selectCollection(at: newIndex)
    }
    
    @IBAction func popUpButtonDidChangeCollection(_ sender: Any) {
        selectCollection(at: collectionsPopUpButton.indexOfSelectedItem)
    }
    
    // Managing Collection's Items
    @IBAction func deleteSelectedItem(_ sender: Any) {
        let row = currentCollectionTableView.selectedRow
        removeCommand(at: row)
    }
    
    @IBAction func insertSeparator(_ sender: Any) {
        let index = currentCollection.items.endIndex
        currentCollection.items.insert(.separator, at: index)
        currentCollectionTableView.insertRows(at: [index], withAnimation: .effectFade)
    }
    
    @IBAction func switchAutoGrouping(_ sender: Any) {
        let checkboxState = autoGroupingCheckboxButton.state == .on ? true : false
        configureAutoGrouping(for: checkboxState)
    }
    
    // Save/Cancel Buttons Actions
    @IBAction func save(_ sender: Any) {
        delegate?.settingsWindowController(self, didUpdate: collections)
        close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        close()
    }
    
    @IBAction func github(_ sender: Any) {
        guard let githubPageUrl = URL(string: "https://github.com/sergeishere/HandyMenu-SketchPlugin") else { return }
        NSWorkspace.shared.open(githubPageUrl)
    }

}
