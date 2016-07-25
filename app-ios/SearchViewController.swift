//
//  SearchViewController.swift
//  CustomSearchBar
//
//  Created by Gabriel Theodoropoulos on 8/9/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import DGElasticPullToRefresh
import TransitionTreasury
import TransitionAnimation
import CellAnimator
import DZNEmptyDataSet
import Crashlytics

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var tblSearchResults:UITableView = UITableView()
    
    let userImageView: UIImageView = UIImageView(frame: CGRectMake(10, 15, 30, 30))
    
    private var dataArray = [User]()
    
    private var filteredArray = [User]()
    
    private var shouldShowSearchResults = false
    
    private var searchController: UISearchController!
    
    private var searchedText:String = ""
    
    private var dateFormatter = NSDateFormatter()
    
    private var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    private var searchOverlayView = UIView()
    
    deinit {
        tblSearchResults.dg_removePullToRefresh()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        
        loadUserAccounts()
        
        configureSearchController()
        
    }

    
    override func viewDidAppear(animated: Bool) {
        // Set nav back button white
        self.searchController.searchBar.hidden = false
        
        if searchController.searchBar.text != "" {
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        let placeholderImageView = UIImageView()
        placeholderImageView.image = UIImage(named: "PlaceholderSearch")
        placeholderImageView.contentMode = .ScaleAspectFit
        placeholderImageView.frame = CGRect(x: searchOverlayView.layer.frame.width/2-140, y: searchOverlayView.layer.frame.height/2, width: 280, height: 280)
        placeholderImageView.center = CGPointMake(self.view.layer.frame.width/2, self.view.layer.frame.height/2-120)
        searchOverlayView.addSubview(placeholderImageView)
        searchOverlayView.backgroundColor = UIColor.whiteColor()
        searchOverlayView.frame = CGRect(x: 0, y: 120, width: screenWidth, height: screenHeight-60)
        
        // definespresentationcontext screen
        self.definesPresentationContext = true
        self.view.backgroundColor = UIColor.slateBlue()
        
        self.navigationItem.title = "Search"
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.lightBlue(),
            NSFontAttributeName : UIFont(name: "MyriadPro-Regular", size: 18)!
        ]
        
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        
        tblSearchResults.reloadData()
        tblSearchResults.delegate = self
        tblSearchResults.dataSource = self
        tblSearchResults.emptyDataSetSource = self
        tblSearchResults.emptyDataSetDelegate = self
        // A little trick for removing the cell separators
        tblSearchResults.tableFooterView = UIView()
        tblSearchResults.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight-42)
        self.view.addSubview(tblSearchResults)
        
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor.whiteColor()
        tblSearchResults.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self?.tblSearchResults.dg_stopLoading()
                self?.loadUserAccounts()
            })
            }, loadingView: loadingView)
        tblSearchResults.dg_setPullToRefreshFillColor(UIColor.mediumBlue())
        tblSearchResults.dg_setPullToRefreshBackgroundColor(UIColor.whiteColor())
    }
    
    // MARK: UITableView Delegate and Datasource functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowSearchResults {
            return filteredArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        self.tblSearchResults.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let CellIdentifier: String = "Cell"
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        
        CellAnimator.animateCell(cell, withTransform: CellAnimator.TransformTilt, andDuration: 0.3)
        
        cell.imageView?.image = nil
        cell.indentationWidth = 5; // The amount each indentation will move the text
        cell.indentationLevel = 2;  // The number of times you indent the text
        cell.textLabel?.textColor = UIColor.darkGrayColor()
        cell.textLabel?.font = UIFont(name: "MyriadPro-Regular", size: 14)
        cell.selectionStyle = UITableViewCellSelectionStyle.Default
        cell.detailTextLabel?.font = UIFont(name: "MyriadPro-Regular", size: 14)
        cell.detailTextLabel?.textColor = UIColor.lightBlue()
        
        cell.imageView!.frame = CGRectMake(10, 15, 30, 30)
        cell.imageView!.backgroundColor = UIColor.clearColor()
        cell.imageView!.layer.cornerRadius = 15
        cell.imageView!.layer.masksToBounds = true
        
        if shouldShowSearchResults {
            // After filtering
            let pic = filteredArray[indexPath.row].picture
            
            cell.textLabel?.text = "@" + String(filteredArray[indexPath.row].username)
             //String(filteredArray[indexPath.row].business_name) ??
            
            if pic != "" {
                let imageView: UIImageView = UIImageView(frame: CGRectMake(10, 15, 30, 30))
                imageView.backgroundColor = UIColor.clearColor()
                imageView.layer.cornerRadius = 15
                imageView.layer.masksToBounds = true
                //                let priority = DISPATCH_QUEUE_PRIORITY_HIGH
                //                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                //                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //                        cell.imageView!. // load image async // (NSURL(string: pic)!, placeholderImage: UIImage(named: "ic_tab_account"))
                //                    })
                //                }
            }
            
            let business_name = filteredArray[indexPath.row].business_name
            let first_name = filteredArray[indexPath.row].first_name
            let last_name = String(filteredArray[indexPath.row].last_name)
            let username = String(filteredArray[indexPath.row].username)
            if business_name != "" {
                cell.detailTextLabel?.text = business_name
                cell.textLabel?.text = "@" + username
            } else if first_name != "" {
                cell.detailTextLabel?.text = first_name + " " + last_name
                cell.textLabel?.text = "@" + username
            } else {
                cell.detailTextLabel?.text = "@" + username
            }
        }
        else {
            // Default loaded array
            let pic = dataArray[indexPath.row].picture
            if pic != "" {
                let imageView: UIImageView = UIImageView(frame: CGRectMake(10, 15, 30, 30))
                imageView.backgroundColor = UIColor.clearColor()
                imageView.layer.cornerRadius = 15
                imageView.layer.masksToBounds = true
                //                let priority = DISPATCH_QUEUE_PRIORITY_HIGH
                //                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                //                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //                        cell.imageView!. // load image async // (NSURL(string: pic)!, placeholderImage: UIImage(named: "ic_tab_account"))
                //                    })
                //                }
            }
            
//            let business_name = dataArray[indexPath.row].business_name
//            let first_name = dataArray[indexPath.row].first_name
//            let last_name = String(dataArray[indexPath.row].last_name)
//            if business_name != "" {
//                cell.detailTextLabel?.text = business_name
//            } else if first_name != "" || last_name != "" {
//                cell.detailTextLabel?.text = first_name + " " + last_name
//            } else {
//                cell.detailTextLabel?.text = String(dataArray[indexPath.row].username)
//            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.shouldShowSearchResults = false
        self.searchController.searchBar.hidden = true
        self.searchController.searchBar.resignFirstResponder()
        self.searchController.searchBar.placeholder = ""
        searchBarCancelButtonClicked(searchController.searchBar)
        
        let user: User
        if searchController.active && searchController.searchBar.text != "" {
            user = filteredArray[indexPath.row]
        } else {
            user = dataArray[indexPath.row]
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SearchDetailViewController") as! SearchDetailViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
        
        vc.detailUser = user
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    // MARK: Custom functions
    
    func loadUserAccounts() {
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        User.getUserAccounts({ (items, error) in
            if error != nil
            {
                let alert = UIAlertController(title: "Error", message: "Could not load user accounts \(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }

            self.dataArray = items!
            
            self.activityIndicator.stopAnimating()
            
            //self.tblSearchResults.reloadData()
        })
    }
    
    func configureSearchController() {
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        //let screenHeight = screen.size.height
        // Initialize and perform a minimum configuration to the search controller.
        searchController = UISearchController(searchResultsController: nil)
        // searchController.searchBar.scopeButtonTitles = ["Merchants", "Users"]
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = ""
        searchController.searchBar.sizeToFit()
        searchController.searchBar.frame = CGRect(x: 0, y: 0, width: screenWidth, height:40)
        searchController.searchBar.translucent = true
        searchController.searchBar.backgroundColor = UIColor.whiteColor()
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.tintColor = UIColor.mediumBlue()
        searchController.searchBar.barStyle = .Black
        searchController.searchBar.showsScopeBar = true
        
        // Place the search bar view to the tableview headerview.
        tblSearchResults.tableHeaderView = searchController.searchBar
        tblSearchResults.bringSubviewToFront(searchController.searchBar)
    }
    
    
    // MARK: UISearchBarDelegate functions
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        // Setup the Scope Bar
        searchBar.setShowsCancelButton(true, animated: true)
        for ob: UIView in ((searchBar.subviews[0] )).subviews {
            if let z = ob as? UIButton {
                let btn: UIButton = z
                btn.setTitleColor(UIColor.mediumBlue(), forState: .Normal)
            }
        }
        shouldShowSearchResults = true
        searchController.searchBar.placeholder = "Enter username or full name"
        tblSearchResults.reloadData()
        searchOverlayView.removeFromSuperview()
        self.tblSearchResults.scrollEnabled = true
        self.tblSearchResults.alwaysBounceVertical = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        shouldShowSearchResults = false
        searchController.searchBar.placeholder = ""
        loadUserAccounts()
        addSubviewWithFade(searchOverlayView, parentView: self, duration: 0.3)
        self.tblSearchResults.scrollEnabled = false
        self.tblSearchResults.alwaysBounceVertical = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if !shouldShowSearchResults {
            shouldShowSearchResults = true
            //tblSearchResults.reloadData()
        }
        self.view.endEditing(true)
        searchController.searchBar.resignFirstResponder()
    }
    
    
    // MARK: UISearchResultsUpdating delegate function
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        
        Answers.logSearchWithQuery(searchString,
                                   customAttributes: nil)
        
        // Filter the data array and get only those users that match the search text.
        filteredArray = dataArray.filter({ (user) -> Bool in
            let fullName = user.first_name + " " + user.last_name
            return (user.username.lowercaseString.containsString(searchString.lowercaseString)) || (user.business_name.lowercaseString.containsString(searchString.lowercaseString) ||  (fullName.lowercaseString.containsString(searchString.lowercaseString)))
        })
        
        // Reload the tableview.
        tblSearchResults.reloadData()
    }
    
    // Refresh
    private func refresh(sender:AnyObject) {
        self.loadUserAccounts()
    }
    
    // Search here
    private func didChangeSearchText(searchText: String) {

        // Filter the data array and get only those users that match the search text.
        filteredArray = dataArray.filter({ (user) -> Bool in
            var userStr: NSString
            if user.business_name != "" {
                userStr = user.business_name
            } else {
                userStr = user.username
            }
            Answers.logSearchWithQuery(searchText,
                customAttributes: nil)
            return (userStr.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch).location) != NSNotFound
        })
        
        // Reload the tableview.
        tblSearchResults.reloadData()
    }
    
    private func filterContentForSearchText(searchText: String, scope: String) {

        filteredArray = filteredArray.filter({( user : User ) -> Bool in
            let fullName = user.first_name + " " + user.last_name
            return (user.username.lowercaseString.containsString(searchText.lowercaseString)) || (user.business_name.lowercaseString.containsString(searchText.lowercaseString) ||  (fullName.lowercaseString.containsString(searchText.lowercaseString)))
        })
        tblSearchResults.reloadData()
    }
    
    
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    
    // MARK: DZNEmptyDataSet delegate
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Search Argent"
        return NSAttributedString(string: str, attributes: headerAttrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Find merchants & users"
        return NSAttributedString(string: str, attributes: bodyAttrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "IconEmptySearch")
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let str = ""
        //let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleCallout)]
        return NSAttributedString(string: str, attributes: calloutAttrs)
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RecurringBillingViewController") as! RecurringBillingViewController
        self.presentViewController(viewController, animated: true, completion: nil)
    }
}

extension UITableView {
    public override func dg_stopScrollingAnimation() {}
}
