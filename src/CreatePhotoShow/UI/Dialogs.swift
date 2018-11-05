//
//  Dialogs.swift
//
//  Copyright © 2018 August Schwerdfeger. All rights reserved.
//

import Foundation
import AppKit

func chooseDirectory() -> URL? {
    let panel = NSOpenPanel()
    
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    
    let result = panel.runModal()
    
    guard result == NSApplication.ModalResponse.OK, panel.urls.isEmpty == false, let url = panel.urls.first else {
        return nil
    }
    return(url)
}

func chooseImages() -> [URL] {
    let panel = NSOpenPanel()
    
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = true
    
    let result = panel.runModal()
    
    guard result == NSApplication.ModalResponse.OK, panel.urls.isEmpty == false else {
        return []
    }
    return(panel.urls)
}

func showErrorDialog(_ messageText: String, informativeText: String) {
    let alert = NSAlert()
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func showInfoDialog(_ messageText: String, informativeText: String) -> Bool {
    let alert = NSAlert()
    alert.icon = nil
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Exit")
    alert.addButton(withTitle: "Continue")
    return alert.runModal() == .alertFirstButtonReturn
}
