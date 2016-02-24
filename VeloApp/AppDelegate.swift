//
//  AppDelegate.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: FirebaseAppDelegate {
    
    var loginViewController: FirebaseLoginViewController!
    
    override init() {
        Firebase.defaultConfig().persistenceEnabled = true
    }
    
    override func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        SetupFirebaseLogin()
        if ((loginViewController.currentUser() == nil)) {
            window.makeKeyAndVisible()
            window.rootViewController!.presentViewController(loginViewController, animated: true, completion: nil)
        }
        else {
            print("already loged in")
            print(loginViewController.currentUser().description)
        }
        
        return true
    }
    
    func SetupFirebaseLogin() {
        let firebaseRef = Firebase(url: "https://purplemist.firebaseio.com/")
        
        loginViewController = FirebaseLoginViewController(ref: firebaseRef)
        //        loginViewController.enableProvider(FAuthProvider.Facebook)
        loginViewController.enableProvider(FAuthProvider.Google)
        //        loginViewController.enableProvider(FAuthProvider.Twitter)
        //        loginViewController.enableProvider(FAuthProvider.Password)
        // Scenario 1: Set up captive portal login flow
        loginViewController.didDismissWithBlock {
            (user: FAuthData!, error: NSError!) -> Void in
            if ((user) != nil) {
                // Handle user case
                print("login callbackd")
                print(user.description)
            } else if ((error) != nil) {
                // Handle error case
            } else {
                // Handle cancel case
            }
        }
    }
    
    override func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    override func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    override func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    override func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    override func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    override func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        super.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        //        super.application(application, url, sourceApplication, annotation);
        // Override point for customization.
        
        return true
    }
    
    
}
