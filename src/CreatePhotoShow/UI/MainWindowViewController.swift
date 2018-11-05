//
//  MainWindowViewController.swift
//
//  Copyright © 2018 August Schwerdfeger. All rights reserved.
//

import Cocoa

class MainWindowViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disableUI("Choose a photo folder")
    }
    
    override var representedObject: Any? {
        didSet {
        }
    }

    @IBOutlet weak var getPhotosButton : NSButton? = nil
    @IBOutlet weak var createButton : NSButton? = nil
    @IBOutlet weak var photoDirectoryP : NSTextField? = nil
    @IBOutlet weak var invalidLabel : NSTextField? = nil
    @IBOutlet weak var photosPerPersonSelector: NSComboBox? = nil
    
    public var photoDirectory : URL? = nil {
        didSet {
            var isDir : ObjCBool = ObjCBool(false)
            if photoDirectory != nil &&
                photoDirectory!.isFileURL && FileManager.default.fileExists(atPath:photoDirectory!.path,isDirectory:&isDir) {
                directoryIsValid = true
            } else {
                directoryIsValid = false
            }
        }
    }
    
    private var totalPhotoCount : Int = 0
    private var maxPhotosPerPerson : Int = 0
    private var photoFilesByInitial : [String:[String]] = [:] {
        didSet {
            maxPhotosPerPerson = getMaxPhotosPerPerson(photoFilesByInitial, hardLimit: 15)
        }
    }
    private var selectedPhotosPerPerson : Int = -1

    private var directoryIsValid : Bool = false {
        didSet {
            updateUI()
        }
    }
    
    private func correctSelectors() {
        if !(0..<maxPhotosPerPerson ~= selectedPhotosPerPerson) {
            selectedPhotosPerPerson = maxPhotosPerPerson
        }
        photosPerPersonSelector?.stringValue = comboBox(photosPerPersonSelector!, objectValueForItemAt: selectedPhotosPerPerson - 1) as! String
    }
    
    private func updateUI() {
        if(directoryIsValid) {
            photoDirectoryP?.stringValue = (photoDirectory?.path) ?? ""
            if let photoDirectoryU = photoDirectory {
                do {
                    photoFilesByInitial = try dirContentsByInitials(photoDirectoryU)
                } catch {
                    photoFilesByInitial = [:]
                }
            }
            if photoFilesByInitial.count != 0 {
                createButton?.isEnabled = true
                photosPerPersonSelector?.isEnabled = true
                invalidLabel?.textColor = nil
                let submitterCount = photoFilesByInitial.count
                totalPhotoCount = getTotalCount(photoFilesByInitial)
                invalidLabel?.stringValue = "\(totalPhotoCount) photo\(totalPhotoCount == 1 ? "" : "s") in folder from \(submitterCount) \(submitterCount == 1 ? "person" : "people")"
                correctSelectors()
            } else {
                disableUI("No images in folder")
            }
            getPhotosButton?.isEnabled = true
        } else {
            photoFilesByInitial = [:]
            disableUI("Invalid folder")
        }

    }
    
    private func disableUI(_ message: String) {
        createButton?.isEnabled = false
        getPhotosButton?.isEnabled = false
        photosPerPersonSelector?.isEnabled = false
        photosPerPersonSelector?.stringValue = ""
        invalidLabel?.textColor = NSColor.red
        invalidLabel?.stringValue = message
    }
    
    @IBAction func photosPerPersonSelectorWasActedUpon(_ sender: NSComboBox) {
        selectedPhotosPerPerson = sender.indexOfSelectedItem + 1
    }

    @IBAction func pathTextDidChange(_ sender: NSTextField) {
        photoDirectory = URL(fileURLWithPath: sender.stringValue)
    }

    @IBAction func createButtonWasPressed(_ sender: AnyObject) {
        let fileManager = FileManager.default
        guard let photoDirectoryA = photoDirectory else { return }

        do {
            let newPhotoFiles = try dirContentsByInitials(photoDirectoryA)
            if newPhotoFiles.keys != photoFilesByInitial.keys ||
                !(newPhotoFiles.keys.map { newPhotoFiles[$0]! == photoFilesByInitial[$0]! }.reduce(true) { $0 && $1 }) {
                showErrorDialog("Try again",informativeText: "Photo show folder has been modified since being selected")
                updateUI()
                return
            }
        } catch {
            showErrorDialog("Error",informativeText: "Photo show folder has been modified since being selected, and could not be reread")
            directoryIsValid = false
            return
        }

        var destPath: URL
            if #available(OSX 10.11, *) {
            destPath = URL(fileURLWithPath: "\(selectedPhotosPerPerson)per-Display", isDirectory: true, relativeTo: photoDirectory)
        } else {
            destPath = URL(fileURLWithPath: "\(photoDirectoryA.path)/\(selectedPhotosPerPerson)per-Display")
        }
        
        do {
            if fileManager.fileExists(atPath: destPath.path) {
                try fileManager.removeItem(at: destPath)
            }
            
            if fileManager.fileExists(atPath: destPath.path) {
            showErrorDialog("Already exists",informativeText: "'\(destPath.path)' already exists and cannot be removed")
                return
            }
            
            try fileManager.createDirectory(at: destPath, withIntermediateDirectories: false)
        } catch {
            showErrorDialog("Error",informativeText: "Error creating folder '\(destPath)'")
            return
        }
        
        do {
            try createPhotoSymlinks(photoFilesByInitial, photoDir: photoDirectoryA, linkDir: destPath, limit: selectedPhotosPerPerson)
        } catch {
            showErrorDialog("Error",informativeText: "Error creating photo show files")
            return
        }
        
        let shouldExit = showInfoDialog("Complete!", informativeText: "Photo show folder created at \(destPath.path)")
        
        if shouldExit {
            NSApplication.shared.terminate(self)
        }

    }
    
    @IBAction func browseButtonWasPressed(_ sender: AnyObject) {
        if let newDirectory = chooseDirectory() {
            photoDirectory = newDirectory
        }
    }

    @IBAction func closeButtonWasPressed(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destWindow = segue.destinationController as? NSWindowController,
            let dest = destWindow.contentViewController as? GetPhotosWindowViewController {
            dest.mainWindowController = self
        }
    }
}

extension MainWindowViewController: NSComboBoxDataSource {
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue: String) -> Int {
        return NSNotFound
    }
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt: Int) -> Any? {
        if !(0..<maxPhotosPerPerson ~= objectValueForItemAt) {
            return nil
        }
        let ppp = objectValueForItemAt + 1
        let total = getLimitedCount(photoFilesByInitial, limit: ppp)
        return "\(ppp) photo\(ppp == 1 ? "" : "s") per person — \(total) total"
    }
    func numberOfItems(in: NSComboBox) -> Int {
        return maxPhotosPerPerson
    }
}
