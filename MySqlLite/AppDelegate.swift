//
//  AppDelegate.swift
//  MySqlLite
//
//  Created by KaiChieh on 02/03/2018.
//  Copyright © 2018 KaiChieh. All rights reserved.


import UIKit
import SQLite3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var db: OpaquePointer? // a kind of pointer for sqlite3

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let fileManager = FileManager.default
        guard let src = Bundle.main.path(forResource: "MyDB", ofType: "sqlite") else {return true} // default file,read only
        let dst = NSHomeDirectory() + "/Documents/myDB.sqlite" // writeable directory

        if !fileManager.fileExists(atPath: dst) {
            try? fileManager.copyItem(atPath: src, toPath: dst)
        }
        objc_sync_enter(self)
        if sqlite3_open(dst, &db) == SQLITE_OK {

        } else {
            objc_sync_exit(self)
            print("open sqlite3 fail")
            db = nil
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        objc_sync_exit(self)
        sqlite3_close(db)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}

