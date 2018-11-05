//
//  GetPhotosWindowViewController.swift
//
//  Copyright © 2018 August Schwerdfeger. All rights reserved.
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
                    let imageRegex = try NSRegularExpression(pattern: Regexes.INITIALS_REGEX)
                    let firstMatch = imageRegex.matches(in:str,range:NSRange(location:0,length:str.count))
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
    @IBOutlet weak var initialsFieldP: NSTextField? = nil
    
    @IBOutlet weak var mainWindowController : MainWindowViewController? = nil/* {
        didSet {
        }
    }*/
    
    var filesToCopy : [URL] = [] {
        didSet {
            updateUI(rereadTable: true)
        }
    }
    
    private func updateUI(rereadTable: Bool) {
        removeButton?.isEnabled = !(tableView?.selectedRowIndexes.isEmpty ?? true)
        if let i = initials {
            initialsFieldP?.stringValue = i
        }
        copyButton?.isEnabled = (initialsAreValid && filesToCopy.count > 0)
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
        let fileManager = FileManager.default
        if let photoDirectoryA = mainWindowController?.photoDirectory {
            for src in filesToCopy {
                let dest = photoDirectoryA.appendingPathComponent((initials ?? "") + "." + src.lastPathComponent)
                if fileManager.fileExists(atPath: dest.path) {
                    showErrorDialog("Failed", informativeText: "Failed to copy \(src.lastPathComponent): Already exists in target directory")
                    break
                }
                do {
                    try fileManager.copyItem(at: src, to: dest)
                    progressBar?.increment(by: 1.0 / Double(filesToCopy.count))
                    progressBar?.display()
                } catch {
                    showErrorDialog("Failed",informativeText: "Failed to copy \(src.lastPathComponent)")
                    break
                }
            }
        } else {
            showErrorDialog("Failed",informativeText: "Copy failed")
        }
        if let mwc = mainWindowController,
            let pdp = mwc.photoDirectoryP {
            mwc.pathTextDidChange(pdp)
        }
        self.view.window?.close()
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
    override func controlTextDidChange(_ obj: Notification) {
        if let str = initialsFieldP?.stringValue,
            str.count > 3 {
            initialsFieldP?.stringValue = String(str.prefix(3))
        }
        initials = initialsFieldP?.stringValue ?? ""
        updateUI(rereadTable: false)
    }
}
