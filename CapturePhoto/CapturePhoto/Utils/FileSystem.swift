//
//  FileSystem.swift
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/14/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

import UIKit

@objc
public class FileSystem: NSObject {
    @objc
    public class func getFolderURL(inDocuments folder: String?) -> URL? {
//        let directoryPaths = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask).map(\.path)
//        let path = directoryPaths[0]
//        let documents = URL(fileURLWithPath: path)

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = paths[0]
        
        var folderURL = path.appendingPathComponent("data")
        
        if !(folder == "") {
            folderURL = folderURL.appendingPathComponent(folder ?? "")
        }

        return folderURL
    }
    
    public class func writeFileDocument(_ data: Data?, atPath folder: String?, inFile fileName: String?, withExtension `extension`: String?) {
        let folderURL = FileSystem.getFolderURL(inDocuments: folder)
        let file = folderURL?.appendingPathComponent(fileName ?? "").appendingPathExtension(`extension` ?? "")

        if let data = data, let file = file {
            NSData(data: data).write(to: file, atomically: true)
        }
    }

    public class func createFolder(inDocuments name: String?) {
        let folder = FileSystem.getFolderURL(inDocuments: name)

        let fileManager = FileManager.default
        do {
            if let folder = folder {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
        }
    }

    public class func renameFolder(inDocuments source: String?, to target: String?) {
        let folderSource = FileSystem.getFolderURL(inDocuments: source)
        let folderTarget = FileSystem.getFolderURL(inDocuments: target)

        let fileManager = FileManager.default
        do {
            if let folderSource = folderSource, let folderTarget = folderTarget {
                try fileManager.moveItem(at: folderSource, to: folderTarget)
            }
        } catch {
        }
    }

    public class func deleteFolder(inDocuments name: String?) {
        let folder = FileSystem.getFolderURL(inDocuments: name)
        let fileManager = FileManager.default

        var dirs: [URL]? = nil
        do {
            if let folder = folder {
                dirs = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            }
        } catch {
        }

        for file in dirs ?? [] {
            do {
                try fileManager.removeItem(at: file)
            } catch {
            }
        }

        do {
            if let folder = folder {
                try fileManager.removeItem(at: folder)
            }
        } catch {
        }
    }

    public class func getFoldersInDocuments() -> [AnyHashable]? {
//        let directoryPaths = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask).map(\.path)
//        let path = directoryPaths[0]
//        let documents = URL(fileURLWithPath: path).appendingPathComponent("data")

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = paths[0]
        
        let documents = path.appendingPathComponent("data")

        let fileManager = FileManager.default

        return try? fileManager.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }

    public class func getFilesInFolder(_ name: String?) -> [AnyHashable]? {
        let folder = FileSystem.getFolderURL(inDocuments: name)

        let fileManager = FileManager.default

        if let folder = folder {
            return try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }
        return nil
    }
}
