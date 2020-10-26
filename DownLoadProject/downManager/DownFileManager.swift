//
//  DownFileManager.swift
//  DownLoadProject
//
//  Created by qinyuan on 2020/10/23.
//

import UIKit

class DownFileManager: NSObject {
    
    /*根据NSURL获取存储的路径,文件不一定存在*/
    static func filePath(url: NSURL) -> String{
        var path: NSString = NSHomeDirectory().appendingFormat("/Documents/downloadDoc/") as NSString
        /*base64编码*/
        let data: NSData = (url.absoluteString! as NSString).lastPathComponent.data(using: String.Encoding.utf8)! as NSData
        let filename:NSString = data.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed) as NSString
        path = path.appending(filename as String) as NSString
        return path as String
    }
    
    /*获取对应文件的大小*/
    static func fileSize(url: NSURL) -> UInt64{
        let path: NSString = DownFileManager.filePath(url: url) as NSString
        var downloadLength: UInt64 = 0
        let fileManager: FileManager = FileManager.default
        if fileManager.fileExists(atPath: path as String) {
            do {
                let fileDict :NSDictionary = try fileManager.attributesOfItem(atPath: path as String) as NSDictionary
                downloadLength = fileDict.fileSize()
            }
            catch let error as NSError{
                print(error.localizedDescription)
            }
        }else {
            if !fileManager.fileExists(atPath: path.deletingLastPathComponent,isDirectory: nil) {
                try! fileManager.createDirectory(atPath: path.deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
            }
            /*文件不存在,创建文件*/
            if !fileManager.createFile(atPath: path as String, contents: nil, attributes: nil) {
                print("create File Error")
            }
        }
        return downloadLength
    }
    
    /*根据url删除对应的文件*/
    static func deleteFile(url:NSURL) ->Bool {
        let path:String = DownFileManager.filePath(url: url)
        let fileManager:FileManager = FileManager.default
        do {
            try! fileManager.removeItem(atPath: path)
        }
        return true
    }
}
