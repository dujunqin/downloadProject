//
//  DownFileSession.swift
//  DownLoadProject
//
//  Created by qinyuan on 2020/10/23.
//

import UIKit

typealias ProgressBlock = (_ progress:Float, _ receive: Int64, _ all: Int64) -> Void
typealias SuccessBlock = (_ path: NSString) -> Void
typealias FailBlock = (_ path: NSString) -> Void
typealias CancelBlock = (_ cancel: Bool) -> Void

class DownFileSession: NSObject, URLSessionDataDelegate {
    var progressBlock: ProgressBlock? = nil
    var successBlock: SuccessBlock? = nil
    var failBlock: FailBlock? = nil
    var cancelBlock: CancelBlock? = nil
    var url: NSURL? = nil
    var path: String? = nil
    var task: URLSessionDataTask? = nil
    var startFileSize: UInt64 = 0
    
    //MARK:异步下载
    func asynDownload(urlStr: NSString,progress: @escaping ProgressBlock, success: @escaping SuccessBlock, failure: @escaping FailBlock, cancel: @escaping CancelBlock) -> DownFileSession {
        let temUrl: NSURL = NSURL.init(string: urlStr as String)!
        let path: String = DownFileManager.filePath(url: temUrl)
        let request: NSMutableURLRequest = NSMutableURLRequest.init(url: temUrl as URL)
        startFileSize = DownFileManager.fileSize(url: temUrl)
        if startFileSize > 0 {
            /*添加本地文件大小到header,告诉服务器我们下载到哪里了*/
            let requestRange: String = String.init(format: "bytes=%llu-", startFileSize)
            request.addValue(requestRange, forHTTPHeaderField: "Range")
        }
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        let session: URLSession = URLSession.init(configuration: config, delegate: self, delegateQueue: OperationQueue.current)
        let task :URLSessionDataTask = session.dataTask(with: request as URLRequest)
        self.progressBlock = progress
        self.successBlock = success
        self.failBlock = failure
        self.cancelBlock = cancel
        self.url = temUrl
        self.path = path
        self.task = task
        task.resume()
        return self
    }
    
    //MARK:取消下载
    func cancel() {
        self.task?.cancel()
        if let temCancelBlock = self.cancelBlock {
            temCancelBlock(true)
        }
    }
    
    //MARK:暂停下载即为取消下载
    func pause() {
        cancel()
    }
    
    //MARK:出现错误,取消请求,通知失败
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let temCancelBlock = self.cancelBlock {
            temCancelBlock(true)
        }
        if let temFailure = self.failBlock {
            temFailure((self.path ?? "") as NSString)
        }
    }
    
    //MARK:下载完成
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let temCancelBlock = self.cancelBlock {
            temCancelBlock(true)
        }
        if let temSuccessBlock = self.successBlock {
            temSuccessBlock((self.path ?? "") as NSString)
        }
    }
    
    //MARK:接收到数据,将数据存储
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let response: HTTPURLResponse = dataTask.response as! HTTPURLResponse
        if response.statusCode == 200 {
            // 无断点续传时候,一直走200
            if let temProgressBlock = self.progressBlock {
                temProgressBlock((Float.init(dataTask.countOfBytesReceived + Int64.init(startFileSize))/Float.init(dataTask.countOfBytesExpectedToReceive + Int64.init(startFileSize))),dataTask.countOfBytesReceived + Int64.init(startFileSize),dataTask.countOfBytesExpectedToReceive + Int64.init(startFileSize))
                
            }
            self.save(data: data as NSData)
        }else if(response.statusCode == 206){
            // 断点续传后,一直走206
            if let temProgressBlock = self.progressBlock {
                temProgressBlock((Float.init(dataTask.countOfBytesReceived + Int64.init(startFileSize))/Float.init(dataTask.countOfBytesExpectedToReceive + Int64.init(startFileSize))),dataTask.countOfBytesReceived + Int64.init(startFileSize),dataTask.countOfBytesExpectedToReceive + Int64.init(startFileSize))
                self.save(data: data as NSData)
            }
        }
    }
    
    //MARK:存储数据,将offset标到文件末尾,在末尾写入数据,最后关闭文件
    func save(data: NSData){
        do{
            let fileHandle: FileHandle = try FileHandle.init(forUpdating: NSURL.fileURL(withPath: (self.path ?? "")))
            fileHandle.seekToEndOfFile()
            fileHandle.write(data as Data)
            fileHandle.closeFile()
        }catch let error as NSError{
            print(error.localizedDescription)
        }
    }
}
