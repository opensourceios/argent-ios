//
//  HomeViewController.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 2/9/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyJSON
import Stripe
import AnimatedSegmentSwitch
import BEMSimpleLineGraph
import DGElasticPullToRefresh
import Gecco
import DZNEmptyDataSet
import CWStatusBarNotification
import CellAnimator
import Crashlytics
import WatchConnectivity

var userAccessToken = NSUserDefaults.standardUserDefaults().valueForKey("userAccessToken")

class HomeViewController: UIViewController, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, WCSessionDelegate  {

    private var window: UIWindow?

    private var screen = UIScreen.mainScreen().bounds

    private var screenWidth = UIScreen.mainScreen().bounds.size.height
    
    private var screenHeight = UIScreen.mainScreen().bounds.size.width
    
    private var dateFormatter = NSDateFormatter()

    private var accountHistoryArray:Array<History>?
    
    private var balance:Balance = Balance(pending: 0, available: 0)
    
    private var tableView:UITableView = UITableView()
    
    private var arrayOfValues: Array<AnyObject> = []

    private var arrayOfDates: Array<AnyObject> = []
    
    private var user = User(id: "", username: "", email: "", first_name: "", last_name: "", business_name: "", picture: "", phone: "", country: "", plaid_access_token: "")
    
    private let lblAccountPending:UILabel = UILabel()

    private let lblAccountAvailable:UILabel = UILabel()
    
    private let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)

    private let balanceSwitch = AnimatedSegmentSwitch()

    private let graph: BEMSimpleLineGraphView = BEMSimpleLineGraphView(frame: CGRectMake(0, 90, UIScreen.mainScreen().bounds.size.width, 200))
    
    private let notification = CWStatusBarNotification()

    private var gradient  : CGGradient?

    @IBAction func indexChanged(sender: AnimatedSegmentSwitch) {
        if(sender.selectedIndex == 0) {
            lblAccountAvailable.removeFromSuperview()
            
            addSubviewWithFade(lblAccountPending, parentView: self, duration: 0.8)
        }
        if(sender.selectedIndex == 1) {
            lblAccountPending.removeFromSuperview()

            addSubviewWithFade(lblAccountAvailable, parentView: self, duration: 0.8)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        
        loadData()
        
        setupAppleWatch()
        
        addInfiniteScroll()
    }
    
    private func addInfiniteScroll() {
        // Add infinite scroll handler
        // change indicator view style to white
        self.tableView.infiniteScrollIndicatorStyle = .Gray
        
        // Add infinite scroll handler
        self.tableView.addInfiniteScrollWithHandler { (scrollView) -> Void in
            let tableView = scrollView as! UITableView
            
            //
            // fetch your data here, can be async operation,
            // just make sure to call finishInfiniteScroll in the end
            //
            if let history_array = self.accountHistoryArray {
                if history_array.count > 98 {
                    let lastIndex = NSIndexPath(forRow: self.accountHistoryArray!.count - 1, inSection: 0)
                    let id = self.accountHistoryArray![lastIndex.row].id
                    // fetch more data with the id
                    self.loadAccountHistory("100", starting_after: id, completionHandler: { (transactions, error) in
                        self.activityIndicator.stopAnimating()
                        if transactions?.count < 1 {
                            self.loadAccountHistory("100", starting_after: "", completionHandler: { _ in
                                self.tableView.reloadData()
                            })
                        }
                    })
                }
            }
            
            // make sure you reload tableView before calling -finishInfiniteScroll
            tableView.reloadData()
            
            // finish infinite scroll animation
            tableView.finishInfiniteScroll()
        }
    }
    
    // VIEW DID APPEAR
    override func viewDidAppear(animated: Bool) {
        self.view.addSubview(balanceSwitch)
        self.view.bringSubviewToFront(balanceSwitch)
        UITextField.appearance().keyboardAppearance = .Light
    }
    
    func setupAppleWatch() {
        print("setting up apple watch")
        // Send access token and Stripe key to Apple Watch
        if userAccessToken != nil && WCSession.isSupported(){ //makes sure it's not an iPad or iPod
            let watchSession = WCSession.defaultSession()
            watchSession.delegate = self
            watchSession.activateSession()
            if watchSession.paired && watchSession.watchAppInstalled {
                do {
                    print(watchSession.paired)
                    print(watchSession.watchAppInstalled)
                    try watchSession.updateApplicationContext(
                        [
                            "token": userAccessToken!
                        ]
                    )
                    print("setting watch data from home")
                } catch let error as NSError {
                    print(error.description)
                }
            }
        }
    }
    
    func presentTutorial(sender: AnyObject) {
        Answers.logCustomEventWithName("Home Tutorial Presented",
                                       customAttributes: [:])
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TutorialHomeViewController") as! TutorialHomeViewController
        viewController.alpha = 0.5
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
    }
    
    func showGraphActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = CGPointMake(self.view.layer.frame.width*0.5, self.view.layer.frame.height*0.3)
        self.view.addSubview(activityIndicator)
    }
    
    func dateRangeSegmentControl(segment: UISegmentedControl) {
        showGraphActivityIndicator()
        if segment.selectedSegmentIndex == 0 {
            showGraphActivityIndicator()
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _2w!
                self.activityIndicator.stopAnimating()
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 1 {
            showGraphActivityIndicator()
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _1m!
                self.activityIndicator.stopAnimating()
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 2 {
            showGraphActivityIndicator()
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _3m!
                self.activityIndicator.stopAnimating()
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 3 {
            showGraphActivityIndicator()
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _6m!
                self.activityIndicator.stopAnimating()
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 4 {
            showGraphActivityIndicator()
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _1y!
                self.activityIndicator.stopAnimating()
                self.graph.reloadGraph()
            })
        }
    }
    
    //Changing Status Bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func loadData() {
        
        // IMPORTANT: load new access token on home load, otherwise the old token will be requested to the server
        userAccessToken = NSUserDefaults.standardUserDefaults().valueForKey("userAccessToken")
        
        if String(userAccessToken) == "" || userAccessToken == nil || String(userAccessToken) == "(null)" {
            self.logout()
        }
        
        activityIndicator.center = tableView.center
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        
        if((userAccessToken) != nil) {
            // Get stripe data
            loadStripe({ (balance, err) in
                let pendingBalance = balance.pending
                let availableBalance = balance.available
                
                NSNotificationCenter.defaultCenter().postNotificationName("balance", object: nil, userInfo: ["available_bal":availableBalance,"pending_bal":pendingBalance])

                let formatter = NSNumberFormatter()
                formatter.numberStyle = .CurrencyStyle
                formatter.locale = NSLocale.currentLocale() // This is the default

                self.lblAccountPending.attributedText = formatCurrency(String(pendingBalance), fontName: "Avenir-Light", superSize: 16, fontSize: 32, offsetSymbol: 10, offsetCents: 10)
                addSubviewWithFade(self.lblAccountPending, parentView: self, duration: 1)
                self.lblAccountAvailable.attributedText = formatCurrency(String(availableBalance), fontName: "Avenir-Light", superSize: 16, fontSize: 32, offsetSymbol: 10, offsetCents: 10)
            })
            
            // Get user account history
            loadAccountHistory("100", starting_after: "", completionHandler: { (historyArr, error) in
                if error != nil {
                    print(error)
                }
                // sets up the empty data set view after load if no data is present
                self.tableView.emptyDataSetSource = self
                self.tableView.emptyDataSetDelegate = self
                self.tableView.tableFooterView = UIView()
                self.activityIndicator.stopAnimating()
            })
            
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _3m!
                self.graph.reloadGraph()
            })
            
            // Get user profile
            User.getProfile({ (user, error) in
                
                if user?.first_name != "" {
                    
                    // Track user action
                    Answers.logCustomEventWithName("User logged in", customAttributes: nil)
                    
                    showGlobalNotification("Welcome " + (user?.first_name)! + "!", duration: 2.5, inStyle: CWNotificationAnimationStyle.Top, outStyle: CWNotificationAnimationStyle.Top, notificationStyle: CWNotificationStyle.StatusBarNotification, color: UIColor.slateBlue())
                }
                
                if(error != nil) {
                    print(error)
                    // check if user logged in, if not send to login
                    self.logout()
                }
            })

        } else {
            // check if user logged in, if not send to login
            self.logout()
        }
    }
    
    func loadAccountHistory(limit: String, starting_after: String, completionHandler: ([History]?, NSError?) -> ()) {
        History.getAccountHistory(limit, starting_after: starting_after, completionHandler: { (transactions, error) in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "Could not load history \(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.accountHistoryArray = transactions
            completionHandler(transactions!, error)
            self.tableView.reloadData()
        })
    }
    
    func loadStripe(completionHandler: (Balance, NSError?) -> ()) {
        // Set account balance label
        
        Balance.getStripeBalance({ (balance, error) in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "Could not load history \(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.balance = balance!
            completionHandler(balance!, error)
        })
    }
    
    // LOGOUT
    func logout() {
        // put in api request to log user out
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "userAccessToken")
        NSUserDefaults.standardUserDefaults().synchronize();
        
        // go to login view
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = sb.instantiateViewControllerWithIdentifier("LoginViewController")
        loginVC.modalTransitionStyle = .CrossDissolve
        let root = UIApplication.sharedApplication().keyWindow?.rootViewController
        root!.presentViewController(loginVC, animated: true, completion: { () -> Void in })
        
        Answers.logCustomEventWithName("Logged User Out from Home",
                                       customAttributes: [:])
    }
    
    // MARK: TableView Delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accountHistoryArray?.count ?? 0
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.tableView.registerNib(UINib(nibName: "HistoryCustomCell", bundle: nil), forCellReuseIdentifier: "idCellCustomHistory")

        let cell = self.tableView.dequeueReusableCellWithIdentifier("idCellCustomHistory") as! HistoryCustomCell

        CellAnimator.animateCell(cell, withTransform: CellAnimator.TransformTilt, andDuration: 0.3)

        let item = self.accountHistoryArray?[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.Blue
        cell.lblAmount?.text = ""
        cell.lblDate?.text = ""
        if let amount = item?.amount {
            if Double(amount)!/100 < 0 {
                // cell.lblCreditDebit?.text = "Debit"
                if APP_THEME == "LIGHT" {
                    cell.img.image = UIImage(named: "ic_arrow_down")
                } else {
                    cell.img.image = UIImage(named: "ic_arrow_down_pink")
                }
                cell.lblAmount?.textColor = UIColor.brandRed()
            } else {
                // cell.lblCreditDebit?.text = "Credit"
                if APP_THEME == "LIGHT" {
                    cell.img.image = UIImage(named: "ic_arrow_up")
                } else {
                    cell.img.image = UIImage(named: "ic_arrow_up_blue")
                }
                cell.lblAmount?.textColor = UIColor.brandGreen()
            }
            
            cell.lblAmount?.attributedText = formatCurrency(amount, fontName: "HelveticaNeue", superSize: 11, fontSize: 15, offsetSymbol: 3, offsetCents: 3)

        }
        if let date = item?.created
        {
            if(!date.isEmpty || date != "") {
                let converted_date = NSDate(timeIntervalSince1970: Double(date)!)
                dateFormatter.dateStyle = .ShortStyle
                dateFormatter.dateFormat = "MMM dd"
                let formatted_date = dateFormatter.stringFromDate(converted_date)
                cell.lblDate?.layer.cornerRadius = 10
                cell.lblDate?.layer.borderColor = UIColor.lightBlue().colorWithAlphaComponent(0.5).CGColor
                cell.lblDate?.textColor = UIColor.lightBlue().colorWithAlphaComponent(0.75)
                cell.lblDate?.layer.borderWidth = 1
                cell.lblDate?.text = String(formatted_date) //+ " / uid " + uid
            } else {
                
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // self.performSegueWithIdentifier("historyDetailView", sender: self)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    // Scrollview

    func scrollViewDidScroll(scrollView: UIScrollView) {
        // TODO: Implement table scroll to top on scrolldown
    }
    
}

extension HomeViewController {
    // Delegate: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Transactions"
        return NSAttributedString(string: str, attributes: headerAttrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "No transactions have occurred yet."
        // let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: bodyAttrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "IconEmptyMoneyBag")
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let str = "Create your first billing plan"
        // let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleCallout)]
        return NSAttributedString(string: str, attributes: calloutAttrs)
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RecurringBillingViewController") as! RecurringBillingViewController
        self.presentViewController(viewController, animated: true, completion: nil)
    }
}

extension HomeViewController {
    
    // MARK: BEM Graph Delegate Methods
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return Int(self.arrayOfValues.count)
        
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        return CGFloat(self.arrayOfValues[index] as! NSNumber)
    }
    
    func numberOfGapsBetweenLabelsOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 2
    }
}

// Used only in HomeViewController
extension UISegmentedControl {
    func removeBorders() {
        setTitleTextAttributes([
                NSForegroundColorAttributeName : UIColor.lightBlue().colorWithAlphaComponent(0.8),
                NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 11)!
            ],
            forState: .Normal)
        setTitleTextAttributes([
                NSForegroundColorAttributeName : UIColor.whiteColor(),
                NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 14)!
            ],
            forState: .Selected)
        setBackgroundImage(imageWithColor(UIColor.clearColor(), source: "IconEmpty"), forState: .Normal, barMetrics: .Default)
        setBackgroundImage(imageWithColor(UIColor.clearColor(), source: "IconEmpty"), forState: .Selected, barMetrics: .Default)
        setDividerImage(imageWithColor(UIColor.clearColor(), source: "IconEmpty"), forLeftSegmentState: .Normal, rightSegmentState: .Normal, barMetrics: .Default)
    }
    
    // create a 1x1 image with this color
    private func imageWithColor(color: UIColor, source: String) -> UIImage {
        let rect = CGRectMake(10.0, 0.0, 100.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
        let image = UIImage(named: source)
        UIGraphicsEndImageContext();
        return image!
    }
}

extension HomeViewController {
    func configureView() {
        
        self.view.backgroundColor = UIColor.darkBlue()
        
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        if let tabBarController = window?.rootViewController as? UITabBarController {
            for item in tabBarController.tabBar.items! {
                if let image = item.image {
                    item.image = image.imageWithRenderingMode(.AlwaysOriginal)
                }
            }
        }
        
        let img: UIImage = UIImage(named: "Logo")!
        let logoImageView: UIImageView = UIImageView(frame: CGRectMake(20, 31, 40, 40))
        logoImageView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        logoImageView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        logoImageView.layer.cornerRadius = logoImageView.frame.size.height/2
        logoImageView.layer.masksToBounds = true
        logoImageView.clipsToBounds = true
        logoImageView.image = img
        logoImageView.layer.borderWidth = 2
        logoImageView.layer.borderColor = UIColor(rgba: "#fffa").CGColor
        // self.view.addSubview(logoImageView)
        
        // Blurview
        let bg: UIImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
        bg.contentMode = .ScaleAspectFill
        bg.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        bg.layer.masksToBounds = true
        bg.clipsToBounds = true
        bg.backgroundColor = UIColor.clearColor()
        self.view.addSubview(bg)
        self.view.sendSubviewToBack(bg)
        
        graph.dataSource = self
        graph.frame = CGRect(x: 0, y: 80, width: screenWidth, height: 150)
        graph.colorTop = UIColor.clearColor()
        graph.colorBottom = UIColor.clearColor()
        graph.colorPoint = UIColor.skyBlue()
        graph.colorBackgroundPopUplabel = UIColor.skyBlue()
        graph.delegate = self
        let gradientColors : [CGColor] = [UIColor.neonBlue().CGColor, UIColor.neonYellow().CGColor, UIColor.neonPink().CGColor]
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        self.gradient = CGGradientCreateWithColors(colorspace, gradientColors, locations)
        graph.gradientLine = self.gradient!
        graph.layer.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor
        graph.layer.shadowOffset = CGSize(width: 2, height: 10)
        graph.layer.shadowRadius = 5
        graph.layer.shadowOpacity = 1
        graph.gradientLineDirection = .Vertical
        graph.widthLine = 4
        graph.displayDotsWhileAnimating = true
        graph.enablePopUpReport = true
        graph.noDataLabelColor = UIColor.lightBlue()
        graph.enableTouchReport = true
        graph.enableBezierCurve = true
        graph.colorTouchInputLine = UIColor.lightBlue()
        graph.layer.masksToBounds = true
        addSubviewWithFade(graph, parentView: self, duration: 0.5)
        
        // split the date segments
        let horizontalSplitter = UIView()
        horizontalSplitter.backgroundColor = UIColor.clearColor()
        horizontalSplitter.frame = CGRect(x: 15.0, y: 260.0, width: screenWidth - 15.0, height: 1)
        self.view.addSubview(horizontalSplitter)
        
        let dateRangeSegment: UISegmentedControl = UISegmentedControl(items: ["2W", "1M", "3M", "6M", "1Y"])
        dateRangeSegment.frame = CGRect(x: 45.0, y: 230.0, width: view.bounds.width - 90.0, height: 30.0)
        //        var y_co: CGFloat = self.view.frame.size.height - 100.0
        //        dateRangeSegment.frame = CGRectMake(10, y_co, width-20, 50.0)
        dateRangeSegment.selectedSegmentIndex = 2
        dateRangeSegment.removeBorders()
        dateRangeSegment.addTarget(self, action: #selector(HomeViewController.dateRangeSegmentControl(_:)), forControlEvents: .ValueChanged)
        addSubviewWithFade(dateRangeSegment, parentView: self, duration: 0.5)
        
        balanceSwitch.items = ["Pending", "Available"]
        balanceSwitch.backgroundColor = UIColor.clearColor()
        balanceSwitch.font = UIFont(name: "Avenir-Light", size: 14)
        balanceSwitch.backgroundColor = UIColor.clearColor()
        balanceSwitch.titleColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        balanceSwitch.selectedTitleColor = UIColor.darkBlue()
        balanceSwitch.frame = CGRect(x: view.bounds.width - 210.0, y: 40, width: 200, height: 32.0)
        //autoresizing so it stays at top right (flexible left and flexible bottom margin)
        balanceSwitch.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        balanceSwitch.bringSubviewToFront(balanceSwitch)
        balanceSwitch.addTarget(self, action: #selector(HomeViewController.indexChanged(_:)), forControlEvents: .ValueChanged)
        
        let headerView: UIView = UIView(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40))
        headerView.backgroundColor = UIColor.clearColor()
        let headerViewTitle: UILabel = UILabel()
        headerViewTitle.frame = CGRect(x: 18, y: 15, width: screenWidth, height: 30)
        headerViewTitle.text = "Transaction History"
        headerViewTitle.font = UIFont.systemFontOfSize(14)
        headerViewTitle.textAlignment = .Left
        headerViewTitle.textColor = UIColor.lightBlue().colorWithAlphaComponent(0.7)
        headerView.addSubview(headerViewTitle)
        
        let tutorialButton:UIButton = UIButton()
        tutorialButton.frame = CGRect(x: screenWidth-40, y: 19, width: 22, height: 22)
        tutorialButton.setImage(UIImage(named: "ic_question"), forState: .Normal)
        tutorialButton.setTitle("Tuts", forState: .Normal)
        tutorialButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        tutorialButton.addTarget(self, action: #selector(HomeViewController.presentTutorial(_:)), forControlEvents: .TouchUpInside)
        tutorialButton.addTarget(self, action: #selector(HomeViewController.presentTutorial(_:)), forControlEvents: .TouchUpOutside)
        headerView.addSubview(tutorialButton)
        headerView.bringSubviewToFront(tutorialButton)
        
        tableView.frame = CGRect(x: 0, y: 270, width: screenWidth, height: screenHeight-315)
        tableView.tableHeaderView = headerView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.lightBlue().colorWithAlphaComponent(0.3)
        tableView.showsVerticalScrollIndicator = false
        addSubviewWithFade(tableView, parentView: self, duration: 0.5)
        
        lblAccountAvailable.textColor = UIColor.whiteColor()
        lblAccountAvailable.frame = CGRectMake(20, 41, 200, 40)
        let str0 = NSAttributedString(string: "N/A", attributes:
            [
                NSFontAttributeName: UIFont.systemFontOfSize(18),
                NSForegroundColorAttributeName:UIColor.whiteColor().colorWithAlphaComponent(0.7)
            ])
        lblAccountAvailable.attributedText = str0
        
        lblAccountPending.textColor = UIColor.whiteColor()
        lblAccountPending.frame = CGRectMake(20, 41, 200, 40)
        let str1 = NSAttributedString(string: "N/A", attributes:
            [
                NSFontAttributeName: UIFont.systemFontOfSize(18),
                NSForegroundColorAttributeName:UIColor.whiteColor().colorWithAlphaComponent(0.7)
            ])
        lblAccountPending.attributedText = str1
        
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor.lightBlue()
        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.tableView.dg_stopLoading()
                self?.loadAccountHistory("100", starting_after: "", completionHandler: { (_: [History]?, NSError) in
                })
            })
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(graph.colorBottom)
        tableView.dg_setPullToRefreshBackgroundColor(self.view.backgroundColor!)
        
        // Transparent navigation bar
        self.navigationController?.navigationBar.barTintColor = UIColor.lightBlue()
        self.navigationController?.navigationBar.tintColor = UIColor.lightBlue()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.mediumBlue(),
            NSFontAttributeName : UIFont(name: "HelveticaNeue-Light", size: 18.0)!
        ]
        
    }
}
