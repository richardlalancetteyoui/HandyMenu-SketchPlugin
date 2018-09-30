//
//  SettingsWindowController.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 18/07/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

public protocol SettingsWindowControllerDelegate: class {
    func settingsWindowController(_ settingsWindowController: SettingsWindowController, didUpdate menuData:[Collection])
    func settingsWindowController(didClose settingsWindowController: SettingsWindowController)
}

public class SettingsWindowController: NSWindowController, SettingsWindowViewControllerDelegate {
    
    // MARK: - Private Outlets
    @IBOutlet private weak var versionLabel: NSTextField!
    @IBOutlet private weak var noPluginsLabel: NSTextField! {
        didSet {
            self.noPluginsLabel.alphaValue = 0.0
        }
    }
    @IBOutlet private weak var emptyListLabel: NSTextField! {
        didSet {
            self.emptyListLabel.alphaValue = 0.0
        }
    }
    @IBOutlet private weak var collectionsPopUpButton: NSPopUpButton!
    @IBOutlet private weak var collectionSettingsMenu: NSMenu!
    @IBOutlet private weak var removeMenuItem: NSMenuItem!
    @IBOutlet private weak var shortcutField: ShortcutField!
    @IBOutlet private weak var insertSeparatorButton: NSButton!
    @IBOutlet private weak var autoGroupingCheckboxButton: NSButton!
    @IBOutlet private weak var collectionsScrollView: NSScrollView!
    @IBOutlet private weak var renamingPanel: InputPanel!
    
    // MARK: - Public Outlets
    @IBOutlet public weak var searchField: SearchField!
    @IBOutlet public weak var installedPluginsCollectionView: NSCollectionView!
    @IBOutlet public weak var deleteItemButton: NSButton!
    @IBOutlet public weak var currentCollectionTableView: NSTableView! {
        didSet {
            // Fixing the first column width
            self.currentCollectionTableView.sizeToFit()
        }
    }
    
    // MARK: - Private Properties
    private let windowViewController = SettingsWindowViewController()
    
    public var currentCollectionIndex: Int = 0
    public var collections: [Collection] = []
    
    public var filteredPlugins: [InstalledPluginData] = [] {
        didSet {
            self.toggleNoPluginsLabel()
        }
    }
    
    public var currentCollection: Collection {
        get {
            return self.collections[self.currentCollectionIndex]
        }
        set {
            self.collections[self.currentCollectionIndex] = newValue
            self.toggleEmptyLabel()
        }
    }
    
    public let commandHeight:CGFloat = 24.0
    public let headerHeight:CGFloat = 48.0
    public let footerHeight: CGFloat = 32.0
    
    public var collectionTableViewRect: NSRect {
        return NSInsetRect(self.currentCollectionTableView.convert(self.collectionsScrollView.bounds, to: nil), -10, -20)
    }
    
    // MARK: - Public Properties
    public weak var delegate: SettingsWindowControllerDelegate?
    public var installedPlugins: [InstalledPluginData] = []
    
    // MARK: - Instance Lifecycle
    override public func windowDidLoad() {
        super.windowDidLoad()
        
        self.installedPluginsCollectionView.delegate = self
        self.installedPluginsCollectionView.dataSource = self
        self.installedPluginsCollectionView.registerForDraggedTypes([.string])
        self.installedPluginsCollectionView.setDraggingSourceOperationMask(.link, forLocal: false)
        
        self.currentCollectionTableView.delegate = self
        self.currentCollectionTableView.dataSource = self
        self.currentCollectionTableView.reloadData()
        self.currentCollectionTableView.registerForDraggedTypes([.string])
        self.currentCollectionTableView.setDraggingSourceOperationMask(.move, forLocal: true)
        
        self.windowViewController.delegate = self
        self.windowViewController.view = self.window!.contentView!
        self.window?.contentViewController = self.windowViewController
        
        self.shortcutField.delegate = self
        
        self.searchField.delegate = self
        
        self.configure(collections)
    }
    
    public override func close() {
        super.close()
        self.window?.makeFirstResponder(nil)
        self.shortcutField.finish(with: nil)
        delegate?.settingsWindowController(didClose: self)
    }
    
    // Refreshing collectionView layout after resizing window (SettingsWindowViewControllerDelegate)
    public func viewWillLayout() {
        self.installedPluginsCollectionView.collectionViewLayout?.invalidateLayout()
    }
    
    // Reseting selection if click on empty space
    public override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(nil)
        self.installedPluginsCollectionView.deselectAll(nil)
        self.currentCollectionTableView.deselectAll(nil)
        self.shortcutField.finish(with: nil)
        super.mouseDown(with: event)
    }
    
    // Public Methods
    public func showCollection(_ collection: String) {
        self.selectCollection(at: self.collectionsPopUpButton.indexOfItem(withTitle: collection))
    }
    
    public func configure(_ collections:[Collection]) {
        self.collections = collections
        
        if self.collections.count == 0 {
            self.collections.append(.emptyCollection)
        }
        
        if self.isWindowLoaded {
            self.currentCollectionTableView.reloadData()
            self.configureCollectionsPopUpButton()
            self.selectCollection(at: self.collections.startIndex)
            self.filterInstalledPlugins(by: "")
            self.versionLabel.stringValue = "Version \(PluginData.currentVersion)"
        }
    }
    
    // Private Methods
    private func configureCollectionsPopUpButton() {
        self.collectionsPopUpButton.removeAllItems()
        self.collectionsPopUpButton.addItems(withTitles: self.collections.map({$0.title}))
    }
    
    private func configureAutoGrouping(for autoGroupingOn: Bool) {
        self.currentCollection.autoGrouping = autoGroupingOn
        self.insertSeparatorButton.isEnabled = !autoGroupingOn
        self.autoGroupingCheckboxButton.state = autoGroupingOn ? .on : .off
        
        if autoGroupingOn, self.currentCollection.items.contains(.separator) {
            var separatorIndexes: IndexSet = []
            for (index, item) in self.currentCollection.items.enumerated() {
                if case CollectionItem.separator = item {
                    separatorIndexes.insert(index)
                }
            }
            self.currentCollection.items = self.currentCollection.items.filter{ $0 != .separator }
            plugin_log("Filtered array: %@", String(describing: self.currentCollection.items))
            self.currentCollectionTableView.removeRows(at: separatorIndexes, withAnimation: .effectFade)
        }
    }
    
    private func toggleEmptyLabel() {
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.duration = 0.2
            self.emptyListLabel.animator().alphaValue = self.currentCollection.items.count > 0 ? 0.0 : 1.0
        })
    }
    
    private func toggleNoPluginsLabel() {
        NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
            context.duration = 0.2
            self.noPluginsLabel.animator().alphaValue = self.filteredPlugins.count > 0 ? 0.0 : 1.0
        })
    }
    
    private func selectCollection(at index: Int) {
        self.currentCollectionIndex = index
        self.collectionsPopUpButton.selectItem(at: index)
        self.installedPluginsCollectionView.reloadData()
        self.currentCollectionTableView.reloadData()
        self.shortcutField.shortcut = self.currentCollection.shortcut
        self.configureAutoGrouping(for: self.currentCollection.autoGrouping)
    }
    
    private func uniqueCollectionTitle() -> String {
        var newTitle = ""
        for freeIndex in 0...self.collections.endIndex {
            newTitle = "New Collection \(freeIndex + 1)"
            guard self.collectionsPopUpButton.itemTitles.contains(newTitle) else { break }
        }
        return newTitle
    }
    
    public func pluginCommandAtIndexPath(_ indexPath: IndexPath) -> Command {
        return self.filteredPlugins[indexPath.section].commands[indexPath.item]
    }
    
    public func removeCommand(at row: IndexSet.Element) {
        self.currentCollection.items.remove(at: row)
        self.currentCollectionTableView.removeRows(at: [row], withAnimation: .effectFade)
        self.installedPluginsCollectionView.reloadData()
    }
    
    
    // Filtering installedPlugins
    private func filterInstalledPlugins(by searchString: String){
        guard searchString.count > 0 else {
            self.filteredPlugins = self.installedPlugins
            self.installedPluginsCollectionView.reloadData()
            return
        }
        
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.filteredPlugins = self.installedPlugins.filter{$0.pluginName.localizedCaseInsensitiveContains(searchString) || $0.commands.contains(where: { $0.name.localizedCaseInsensitiveContains(searchString)}
                )}
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
        guard let sourceIndexPath = self.installedPluginsCollectionView.indexPath(for: item) else { return }
        self.insertNewCommand(from: sourceIndexPath, to: self.currentCollection.items.endIndex)
    }
}

// MARK: - ShortcutFieldDelegate
extension SettingsWindowController: ShortcutFieldDelegate {
    func shortcutField(_ shortcutField: ShortcutField, didChange shortcut: Shortcut) {
        self.currentCollection.shortcut = shortcut
    }
}

// MARK: - SearchField Delegate {
extension SettingsWindowController: SearchFieldDelegate {
    public func searchField(_ searchField: SearchField, didChanged value: String) {
        self.filterInstalledPlugins(by: value)
    }
}

// MARK: - Actions Handling
extension SettingsWindowController {
    
    // Managing Selected Collection
    @IBAction func openCollectionSettings(_ sender: Any) {
        self.removeMenuItem.isEnabled = self.collections.count > 1 ? true : false
        if let sender = sender as? NSButton {
            let point = NSPoint(x: 0, y: sender.bounds.height)
            self.collectionSettingsMenu.popUp(positioning: nil, at: point, in: sender)
        }
    }
    
    @IBAction func renameCollection(_ sender: Any) {
        guard let window = self.window else { return }
        self.renamingPanel.value = self.currentCollection.title
        self.renamingPanel.beginSheet(for: window) { [weak self] (response) in
            guard let value = self?.renamingPanel.value,
                !value.isEmpty,
                self?.collectionsPopUpButton.selectedItem?.title != value else { return }
            if let strongSelf = self {
                let newValue = strongSelf.collectionsPopUpButton.itemTitles.contains(value) ? value + " copy" : value
                strongSelf.currentCollection.title = newValue
                strongSelf.collectionsPopUpButton.selectedItem?.title = newValue
            }
        }
    }
    
    @IBAction func removeCollection(_ sender: Any) {
        self.collections.remove(at: self.currentCollectionIndex)
        let lastIndex = self.collections.index(before: self.collections.endIndex)
        let newIndex = (self.currentCollectionIndex > lastIndex) ? lastIndex : currentCollectionIndex
        self.configureCollectionsPopUpButton()
        self.selectCollection(at: newIndex)
    }
    
    @IBAction func addNewCollection(_ sender: Any) {
        let newIndex = self.collections.endIndex
        var newCollection = Collection.emptyCollection
        newCollection.title = uniqueCollectionTitle()
        self.collections.insert(newCollection, at: newIndex)
        self.configureCollectionsPopUpButton()
        self.selectCollection(at:newIndex)
    }
    
    @IBAction func popUpButtonDidChangeCollection(_ sender: Any) {
        self.selectCollection(at: self.collectionsPopUpButton.indexOfSelectedItem)
    }
    
    // Managing Collection's Items
    @IBAction func deleteSelectedItem(_ sender: Any) {
        let row = self.currentCollectionTableView.selectedRow
        self.removeCommand(at: row)
    }
    
    @IBAction func insertSeparator(_ sender: Any) {
        let index = self.currentCollection.items.endIndex
        self.currentCollection.items.insert(.separator, at: index)
        self.currentCollectionTableView.insertRows(at: [index], withAnimation: .effectFade)
    }
    
    @IBAction func switchAutoGrouping(_ sender: Any) {
        let checkboxState = self.autoGroupingCheckboxButton.state == .on ? true : false
        self.configureAutoGrouping(for: checkboxState)
    }
    

    // Save/Cancel Buttons Actions
    @IBAction func save(_ sender: Any) {
        self.delegate?.settingsWindowController(self, didUpdate: collections)
        self.close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.close()
    }
    
    @IBAction func github(_ sender: Any) {
        guard let githubPageUrl = URL(string: "https://github.com/sergeishere/HandyMenu-SketchPlugin") else { return }
        NSWorkspace.shared.open(githubPageUrl)
    }

}


