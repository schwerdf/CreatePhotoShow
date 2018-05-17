//
//  CreatePhotoShow.swift
//  CreatePhotoShow
//
//  Copyright © 2018 August Schwerdfeger. All rights reserved.
//

import Foundation

fileprivate let IMAGE_REGEX = "^(W\\.)?([A-Za-z][A-Za-z][A-Za-z]?)([-._ ].*)\\.[Jj][Pp]([Ee])?[Gg]"
fileprivate let PREFIX_ELIMINATION_REGEX = "^([Ww]\\.)?([A-Za-z][A-Za-z][A-Za-z]?[-._ ].*)\\.[Jj][Pp]([Ee])?[Gg]"


func initialsComparator(s1: String, s2: String, prefixEliminationRegex: NSRegularExpression) -> Bool {
    let s1Match = prefixEliminationRegex.matches(in:s1,range:NSRange(location:0,length:s1.count))
    let s2Match = prefixEliminationRegex.matches(in:s2,range:NSRange(location:0,length:s2.count))
    let s1Index = s1.index(s1.startIndex,offsetBy:s1Match[0].range(at:2).location)
    let s2Index = s2.index(s2.startIndex,offsetBy:s2Match[0].range(at:2).location)
    
    return s1[s1Index..<s1.index(s1Index,offsetBy: s1Match[0].range(at:2).length)] <= s2[s2Index..<s2.index(s2Index,offsetBy: s2Match[0].range(at:2).length)]
}

func dirContentsByInitials(_ dir: URL) throws -> [String:[String]] {
    let fileManager = FileManager.default
    
    let imageRegex = try NSRegularExpression(pattern: IMAGE_REGEX)
    let prefixEliminationRegex = try NSRegularExpression(pattern: PREFIX_ELIMINATION_REGEX)

    var rv : [String:[String]] = [:]
    
    let files = try fileManager.contentsOfDirectory(atPath:dir.path)
    
    for file in files {
        let firstMatch = imageRegex.matches(in:file,range:NSRange(location:0,length:file.count))
        if firstMatch.count > 0 {
            let initialStartIndex = file.index(file.startIndex,offsetBy:firstMatch[0].range(at:2).location)
            
            let initials = String(file[initialStartIndex..<file.index(initialStartIndex, offsetBy:firstMatch[0].range(at:2).length)])
            if rv[initials] == nil {
                rv[initials] = []
            }
            rv[initials]!.append(file)
        }
    }
    
    for initials in rv.keys {
        rv[initials]!.sort(by: { (s1: String, s2: String) -> Bool in initialsComparator(s1: s1, s2: s2, prefixEliminationRegex: prefixEliminationRegex) })
        //print(rv[initials]!)
    }
    
    return rv
}

func getLimitedCount(_ photoFilesByInitial: [String:[String]], limit: Int) -> Int {
    return Array(photoFilesByInitial.values).reduce(0) { $0 + min($1.count,limit) }
}

func getTotalCount(_ photoFilesByInitial: [String:[String]]) -> Int {
    return getLimitedCount(photoFilesByInitial, limit:Int.max)
}

func getMaxPhotosPerPerson(_ photoFilesByInitial: [String:[String]], hardLimit: Int) -> Int {
    return Array(photoFilesByInitial.values).reduce(0) { max($0, min($1.count, hardLimit)) }
}

func createPhotoSymlinks(_ photoFilesByInitial: [String:[String]], photoDir: URL, linkDir: URL, limit: Int) throws {
    let fileManager = FileManager.default
    let allPhotos = photoFilesByInitial.keys.reduce([]) {
        $0 + photoFilesByInitial[$1]![0..<(min(photoFilesByInitial[$1]!.count,limit))]
    }
    for photo in allPhotos {
        try fileManager.createSymbolicLink(at: URL(fileURLWithPath: "\(linkDir.path)/\(photo)"),
                                           withDestinationURL: URL(fileURLWithPath: "\(photoDir.path)/\(photo)"))
    }
}


