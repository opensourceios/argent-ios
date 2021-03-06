//
//  CountryPickerViewController.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 4/25/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import Foundation
import CountryPicker
import FlagKit
import UIKit
import Spring

class SignupCountryPickerViewController:UIViewController, CountryPickerDelegate, UITextFieldDelegate {
    
    let codeLabel:SpringLabel = SpringLabel()

    let flagImg:SpringImageView = SpringImageView()
    
    let countryPicker:CountryPicker = CountryPicker()
    
    let unsupportedImageView = UIImageView()
    
    let unsupportedTextLabel = UILabel()
    
    let toolBar = UIToolbar()

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func viewDidAppear(animated: Bool) {
        codeLabel.animation = "fadeInUp"
        codeLabel.duration = 1.2
        codeLabel.animate()
        addSubviewWithFade(codeLabel, parentView: self, duration: 0.7)
        
        flagImg.animation = "fadeInUp"
        flagImg.duration = 1
        flagImg.animate()
        addSubviewWithFade(flagImg, parentView: self, duration: 0.9)
        
        addSubviewWithFade(countryPicker, parentView: self, duration: 0.3)
    }
    
    override func viewWillDisappear(animated: Bool) {
        codeLabel.animation = "fadeInUp"
        codeLabel.duration = 2
        codeLabel.animateTo()
        addSubviewWithFade(codeLabel, parentView: self, duration: 0.7)
        
        flagImg.animation = "fadeInUp"
        flagImg.duration = 2.5
        flagImg.animateTo()
        addSubviewWithFade(flagImg, parentView: self, duration: 0.9)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addToolbarButton()
        
        self.view.backgroundColor = UIColor.whiteColor()

        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        unsupportedImageView.image = UIImage(named: "IconAlert")
        unsupportedImageView.frame = CGRect(x: screenWidth/2-20, y: screenHeight*0.4, width: 40, height: 40)
        
        unsupportedTextLabel.text = "Only US accounts are currently supported"
        unsupportedTextLabel.frame = CGRect(x: 0, y: screenHeight*0.45, width: screenWidth, height: 40)
        unsupportedTextLabel.textAlignment = .Center
        unsupportedTextLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightLight)
        unsupportedTextLabel.textColor = UIColor.brandRed()
        
        let countryPickerBackgroundView = UIView()
        countryPickerBackgroundView.backgroundColor = UIColor.whiteColor()
        countryPickerBackgroundView.frame = CGRect(x: 0, y: screenHeight-210, width: screenWidth, height: 210)
        self.view.addSubview(countryPickerBackgroundView)
        self.view.sendSubviewToBack(countryPickerBackgroundView)
        
        // Set default country code
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
        NSUserDefaults.standardUserDefaults().setValue(countryCode, forKey: "userCountry")

        flagImg.image = UIImage(flagImageWithCountryCode: NSLocale.autoupdatingCurrentLocale().objectForKey(NSLocaleCountryCode) as! String)
        flagImg.layer.cornerRadius = 10
        flagImg.layer.masksToBounds = true
        flagImg.contentMode = .ScaleAspectFit
        
        let countryName: String = NSLocale.systemLocale().displayNameForKey(NSLocaleCountryCode, value: countryCode)!
        codeLabel.tintColor = UIColor.lightBlue()
        codeLabel.textAlignment = .Center
        let str = NSAttributedString(string: countryName, attributes:
            [
                NSFontAttributeName: UIFont(name: "SFUIText-Light", size: 24)!,
                NSForegroundColorAttributeName:UIColor.lightBlue()
            ])
        codeLabel.attributedText = str
        
        // Check for iPhone 4 size screen
        if screenHeight < 500 {
            flagImg.frame = CGRect(x: screenWidth/2-15, y: screenHeight*0.15, width: 30, height: 30)
            codeLabel.frame = CGRect(x: 0, y: screenHeight*0.22, width: screenWidth, height: 50)
        } else {
            flagImg.frame = CGRect(x: screenWidth/2-15, y: screenHeight*0.22, width: 30, height: 40)
            codeLabel.frame = CGRect(x: 0, y: screenHeight*0.28, width: screenWidth, height: 50)
        }
        
        countryPicker.selectedLocale = NSLocale.currentLocale()
        countryPicker.delegate = self
        countryPicker.frame = CGRect(x: 0, y: screenHeight-215, width: screenWidth, height: 300)
        
        self.navigationController?.view.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 65))
        navBar.translucent = true
        navBar.tintColor = UIColor.whiteColor()
        navBar.backgroundColor = UIColor.clearColor()
        navBar.shadowImage = UIImage()
        navBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 17)!,
            NSForegroundColorAttributeName:UIColor.lightBlue()
        ]
        self.view.addSubview(navBar)
        let navItem = UINavigationItem(title: "Select your Country")
        navItem.leftBarButtonItem?.tintColor = UIColor.darkGrayColor()
        navBar.setItems([navItem], animated: true)
    }
    
    // Add send toolbar
    func addToolbarButton() {
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        countryPicker.backgroundColor = UIColor.clearColor()
        countryPicker.showsSelectionIndicator = true
        self.view.sendSubviewToBack(countryPicker)
        countryPicker.sendSubviewToBack(countryPicker)

        toolBar.frame = CGRect(x: 0, y: screenHeight-250, width: screenWidth, height: 50)
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = false
        toolBar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let next: UIBarButtonItem = UIBarButtonItem(title: "Continue", style: UIBarButtonItemStyle.Done, target: self, action: #selector(SignupCountryPickerViewController.nextStep(_:)))

        UIToolbar.appearance().barTintColor = UIColor.brandGreen()
        UIToolbar.appearance().backgroundColor = UIColor.brandGreen()

        next.setTitleTextAttributes([
            NSFontAttributeName : UIFont(name: "SFUIText-Regular", size: 15)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
            ], forState: .Normal)
        
        toolBar.setItems([flexSpace, next, flexSpace], animated: false)
        toolBar.userInteractionEnabled = true
        
        addSubviewWithFade(toolBar, parentView: self, duration: 0.5)
        self.view.superview?.bringSubviewToFront(toolBar)
        self.view.superview?.sendSubviewToBack(countryPicker)
        self.view.bringSubviewToFront(toolBar)
    }
    
    func nextStep(sender: AnyObject) {
        // Function for toolbar button
        let entity = NSUserDefaults.standardUserDefaults().stringForKey("userLegalEntityType")!
        if entity == "individual" {
            self.performSegueWithIdentifier("VC1i", sender: sender)
        } else {
            self.performSegueWithIdentifier("VC1c", sender: sender)
        }
    }
    
    func countryPicker(picker: CountryPicker, didSelectCountryWithName name: String, code: String) {
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        // Update country code to picked country
        NSUserDefaults.standardUserDefaults().setValue(code, forKey: "userCountry")

        // prevent re-adding image
        flagImg.removeFromSuperview()
        flagImg.layer.cornerRadius = 10
        flagImg.layer.masksToBounds = true
        flagImg.contentMode = .ScaleAspectFit
        flagImg.image = UIImage(flagImageWithCountryCode: code)
        flagImg.frame = CGRect(x: screenWidth/2-15, y: screenHeight*0.22, width: 30, height: 30)
        
        codeLabel.removeFromSuperview()
        codeLabel.text = name
        codeLabel.tintColor = UIColor.lightBlue()
        codeLabel.frame = CGRect(x: 0, y: screenHeight*0.3, width: screenWidth, height: 50)
        codeLabel.textAlignment = .Center
        let str = NSAttributedString(string: name, attributes:
            [
                NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 24)!,
                NSForegroundColorAttributeName:UIColor.lightBlue()
            ])
        codeLabel.attributedText = str
        
        // Check for iPhone 4 size screen
        if screenHeight < 500 {
            flagImg.frame = CGRect(x: screenWidth/2-15, y: screenHeight*0.15, width: 30, height: 30)
            codeLabel.frame = CGRect(x: 0, y: screenHeight*0.22, width: screenWidth, height: 50)
        } else {
            flagImg.frame = CGRect(x: screenWidth/2-15, y: screenHeight*0.22, width: 30, height: 30)
            codeLabel.frame = CGRect(x: 0, y: screenHeight*0.28, width: screenWidth, height: 50)
        }

        codeLabel.animation = "fadeInUp"
        codeLabel.duration = 1.2
        codeLabel.animate()
        addSubviewWithFade(codeLabel, parentView: self, duration: 0.7)
        
        flagImg.animation = "fadeInUp"
        flagImg.duration = 1
        flagImg.animate()
        addSubviewWithFade(flagImg, parentView: self, duration: 0.9)
        
        if code == "US" {
            // print("country supported")
            unsupportedTextLabel.removeFromSuperview()
            unsupportedImageView.removeFromSuperview()
            addToolbarButton()
            addSubviewWithFade(countryPicker, parentView: self, duration: 0.3)
        } else {
            print("this country is not currently supported")
            toolBar.removeFromSuperview()
            codeLabel.animation = "fadeIn"
            codeLabel.duration = 1.7
            codeLabel.animate()
            addSubviewWithFade(unsupportedImageView, parentView: self, duration: 0.7)
            
            flagImg.animation = "fadeIn"
            flagImg.duration = 1.5
            flagImg.animate()
            addSubviewWithFade(unsupportedTextLabel, parentView: self, duration: 0.9)
        }
    }
}