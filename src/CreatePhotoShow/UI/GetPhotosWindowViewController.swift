//
//  GetPhotosWindowViewController.swift
//
//  Copyright © 2018-2019 August Schwerdfeger
//

import Foundation

import Cocoa

class GetPhotosWindowViewController: NSViewController {
    @IBOutlet weak var copyButton: NSButton? = nil
    @IBOutlet weak var removeButton: NSButton? = nil
    @IBOutlet weak var tableView: NSTableView? = nil
    @IBOutlet weak var progressBar: NSProgressIndicator? = nil
    var initials: String? = nil {
        didSet {
            do {
                if let str = initials {
                    let imageRegex = try NSRegularExpression(pattern: Regexes.INITIALS_REGEX, options: Regexes.REGEX_OPTIONS)
                    let firstMatch = imageRegex.matches(in:str,range:NSRange(0..<str.utf16.count))
                    initialsAreValid = firstMatch.count > 0
                } else {
                    initialsAreValid = false
                }
            } catch {
                initialsAreValid = false
            }
        }
    }
    private var initialsAreValid: Bool = false {
        didSet {
            updateUI(rereadTable: false)
        }
    }
    private var copying: Bool = false {
        didSet {
            updateUI(rereadTable: false)
        }
    }
    @IBOutlet weak var initialsFieldP: NSTextField? = nil
    
    @IBOutlet weak var mainWindowController : MainWindowViewController? = nil/* {
        didSet {
        }
    }*/
    
    var filesToCopy : [URL] = [] {
        didSet {
            if initials == nil || initials! == "" {
                do {
                    let newInitials = try getInitials(files: filesToCopy)
                    if Set(newInitials).count == 1 && newInitials[0] != "" {
                        initialsFieldP?.stringValue = newInitials[0]
                        initials = newInitials[0]
                    }
                } catch {
                    // Intentionally left blank.
                }
            }
            updateUI(rereadTable: true)
        }
    }
    
    private func updateUI(rereadTable: Bool) {
        removeButton?.isEnabled = !(tableView?.selectedRowIndexes.isEmpty ?? true)
        copyButton?.isEnabled = (initialsAreValid && filesToCopy.count > 0 && !copying)
        if rereadTable {
            tableView?.noteNumberOfRowsChanged()
            tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI(rereadTable: true)
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBAction func copyButtonWasPressed(_ sender: AnyObject) {
        copying = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
              return
            }
            self.doFileCopy()
        }
    }
    
    func doFileCopy() {
        var errorString : String? = nil
        let fileManager = FileManager.default
        if let photoDirectoryA = mainWindowController?.photoDirectory {
            var allInitials : [String] = []
            do {
                allInitials = try getInitials(files: filesToCopy)
            } catch {
                // Intentionally left blank.
            }
            let allInitialsS = Set(allInitials)
            
            for src in filesToCopy {
                var initialsPrefix : String = (initials ?? "") + "."
                if allInitialsS.count == 1,
                   let initialsS = initials,
                   allInitials[0] == initialsS {
                    initialsPrefix = ""
                }

                let dest = photoDirectoryA.appendingPathComponent(initialsPrefix + src.lastPathComponent)
                if fileManager.fileExists(atPath: dest.path) {
                    errorString = "Failed to copy \(src.lastPathComponent): Already exists in target directory"
                    break
                }
                do {
                    try fileManager.copyItem(at: src, to: dest)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                          return
                        }
                        self.progressBar?.increment(by: 100.0 / Double(self.filesToCopy.count))
                    }
                } catch {
                    errorString = "Failed to copy \(src.lastPathComponent)"
                    break
                }
            }
        } else {
            errorString = "Copy failed"
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
              return
            }
            if let errorStringS = errorString {
                showErrorDialog("Failed",informativeText: errorStringS)
            }
            if let mwc = self.mainWindowController,
                let pdp = mwc.photoDirectoryP {
                mwc.pathTextDidChange(pdp)
            }
            self.view.window?.close()
        }
    }
    
    @IBAction func addButtonWasPressed(_ sender: AnyObject) {
        let newURLs = chooseImages()
        let inPlace = Set(filesToCopy)
        filesToCopy += newURLs.filter { !inPlace.contains($0) }
    }
    
    @IBAction func removeButtonWasPressed(_ sender: AnyObject) {
        if let indices = tableView?.selectedRowIndexes {
            var i = -1
            filesToCopy = filesToCopy.filter { _ in i = i+1; return !indices.contains(i)
                
            }
        }
    }

    @IBAction func closeButtonWasPressed(_ sender: AnyObject) {
        self.view.window?.close()
    }
}

extension GetPhotosWindowViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filesToCopy.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView {
            result.textField?.stringValue = filesToCopy[row].lastPathComponent
            return result
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateUI(rereadTable: false)
    }
}

extension GetPhotosWindowViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let str = initialsFieldP?.stringValue,
            str.count > 3 {
            initialsFieldP?.stringValue = String(str.prefix(3))
        }
        initials = initialsFieldP?.stringValue ?? ""
        updateUI(rereadTable: false)
    }
}
