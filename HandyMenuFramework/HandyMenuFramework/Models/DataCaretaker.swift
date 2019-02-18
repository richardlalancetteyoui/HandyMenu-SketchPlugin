//
//  HMDataLoader.swift
//  HandyMenuFramework
//
//  Created by Sergey Dmitriev on 14/06/2018.
//  Copyright © 2018 Sergey Dmitriev. All rights reserved.
//

public class DataCaretaker {
    
    // MARK: - Handling keys
    private let suiteName = "com.sergeishere.plugins.handymenu"
    private let dataKey = "plugin_sketch_handymenu_data"
    
    // MARK: - Instance Properties
    private lazy var userDefaults = { UserDefaults(suiteName: suiteName) ?? UserDefaults.standard }()
    
    private lazy var encoder = { JSONEncoder() }()
    private lazy var decoder = { JSONDecoder() }()
    
    public func retrieve() -> PluginData? {
        guard
            let encodedData = userDefaults.data(forKey: dataKey),
            let data = try? decoder.decode(PluginData.self, from: encodedData)
            else { return nil }
        return data
    }
    
    public func save(_ data: PluginData) -> Bool {
        guard let encodedData = try? encoder.encode(data) else { return false }
        userDefaults.setValue(encodedData, forKey: dataKey)
        return true
    }
    
}
