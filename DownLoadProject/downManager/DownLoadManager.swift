//
//  DownLoadManager.swift
//  DownLoadProject
//
//  Created by qinyuan on 2020/10/26.
//

import UIKit

var sessionArray: NSMutableArray = NSMutableArray.init(capacity: 50)

class DownLoadManager: NSObject {
    //MARK:异步下载
    static func asynDownLoad(urlStr: NSString, progress:@escaping ProgressBlock, success:@escaping SuccessBlock,failure:@escaping FailBlock) -> DownFileSession{
        for session in sessionArray {
            if (((session as! DownFileSession).url?.absoluteString?.isEqual(urlStr)) == true) {
                return session as! DownFileSession;
            }
        }
        let session: DownFileSession = DownFileSession().asynDownload(urlStr: urlStr, progress: progress, success: success, failure: failure) { (Bool) in
            // 取消请求,数组中将移除对应的请求
            for session in sessionArray {
                if (((session as! DownFileSession).url?.absoluteString?.isEqual(urlStr)) == true) {
                    sessionArray.remove(session)
                    break;
                }
            }
        }
        // 添加到数组
        sessionArray.add(session)
        return session
    }
    
    //MARK:取消
    static func cancel(urlStr: String){
        //查找数组中对应的请求
        for session in sessionArray {
            if ((session as! DownFileSession).url?.absoluteString?.isEqual(urlStr)) == true {
                (session as! DownFileSession).cancel()
                break
            }
        }
    }
    //MARK:暂停
    static func pause(urlStr: String){
        for session in sessionArray {
            if (((session as! DownFileSession).url?.absoluteString?.isEqual(urlStr)) == true) {
                (session as! DownFileSession).pause()
                break;
            }
        }
    }
}
