//
//  WebTermsViewController.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 3/27/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import CWStatusBarNotification

class WebTermsViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet var containerView : UIView!
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()

        self.webView = WKWebView()
        self.webView?.UIDelegate = self
        self.view = self.webView!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string:"https://www.argentapp.com/terms")
        let req = NSURLRequest(URL:url!)
        self.webView!.loadRequest(req)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    lazy var previewActions: [UIPreviewActionItem] = {
        func previewActionForTitle(title: String, style: UIPreviewActionStyle = .Default) -> UIPreviewAction {
            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
//                guard let detailViewController = viewController as? DetailViewController,
//                    item = detailViewController.detailItemTitle else { return }
//                print("\(previewAction.title) triggered from `DetailViewController` for item: \(item)")
                if title == "Copy Link" {
                    UIPasteboard.generalPasteboard().string = "https://www.argentapp.com/terms"
                    showGlobalNotification("Link copied!", duration: 3.0, inStyle: CWNotificationAnimationStyle.Top, outStyle: CWNotificationAnimationStyle.Top, notificationStyle: CWNotificationStyle.StatusBarNotification, color: UIColor.skyBlue())
                }
                if title == "Share" {
                    let activityViewController  = UIActivityViewController(
                        activityItems: ["Argent Terms and Conditions  https://www.argentapp.com/terms" as NSString],
                        applicationActivities: nil)
                    activityViewController.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                    self.presentViewController(activityViewController, animated: true, completion: nil)
                }
            }
        }
        
        let action1 = previewActionForTitle("Copy Link")
//        return [action1]
        let action2 = previewActionForTitle("Share")
        return [action1, action2]

//        let action2 = previewActionForTitle("Share", style: .Destructive)
//        let subAction1 = previewActionForTitle("Sub Action 1")
//        let subAction2 = previewActionForTitle("Sub Action 2")
//        let groupedActions = UIPreviewActionGroup(title: "More", style: .Default, actions: [subAction1, subAction2] )
//        return [action1, action2, groupedActions]
        
    }()
    
    
    override func previewActionItems() -> [UIPreviewActionItem] {
        return previewActions
    }
    
}