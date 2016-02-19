//
//  AppDelegate.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import Realm

func realmPath(name: String) -> String {
    let path: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    return path.stringByAppendingPathComponent(name)
}

extension RLMRealm {
    func addProperty(property: RLMProperty, to className: String, defaultValue: AnyObject? = nil) {
        let objectSchema = schema[className]
        objectSchema.properties += [property]
        
        let config = configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        if let defaultValue = defaultValue {
            config.migrationBlock = { migration, oldVersion in
                if oldVersion < newVersion {
                    migration.enumerateObjects(className) { oldObject, newObject in
                        newObject?[property.name] = defaultValue
                    }
                }
            }
        }
        
        RLMRealm.migrateRealm(config)
    }
    
    class func dynamicRealm(name: String, schema: RLMSchema? = nil) throws -> RLMRealm {
        return try RLMRealm(path: realmPath(name) + ".realm", key: nil, readOnly: false, inMemory: false, dynamic: true, schema: schema)
    }
}

class MyVC: UIViewController {
    var mySchema: RLMSchema {
        let prop1 = RLMProperty(name: "aString", type: .String, objectClassName: nil, indexed: false, optional: false)
        let prop2 = RLMProperty(name: "aDouble", type: .Double, objectClassName: nil, indexed: false, optional: false)
        
        let objectSchema = RLMObjectSchema(className: "MyClass", objectClass: RLMObject.self, properties: [prop1, prop2])
        let schema = RLMSchema()
        schema.objectSchema = [objectSchema]
        
        return schema
    }
    
    func ggg1() {
        let realm = try! RLMRealm.dynamicRealm("test", schema: mySchema)

        realm.beginWriteTransaction()
        let obj = realm.createObject("MyClass", withValue: ["tolv", 12])
        realm.addObject(obj)
        try! realm.commitWriteTransaction()
    }
    
    func ggg2() {
        // Create new properties
        let prop3 = RLMProperty(name: "anotherString", type: .String, objectClassName: nil, indexed: false, optional: false)
        let prop4 = RLMProperty(name: "anotherDouble", type: .Double, objectClassName: nil, indexed: false, optional: false)
        let prop5 = RLMProperty(name: "aDate", type: .Date, objectClassName: nil, indexed: false, optional: false)
        
        // Bump schema version
        try! RLMRealm.dynamicRealm("test").addProperty(prop3, to: "MyClass", defaultValue: "palle klanka")
        try! RLMRealm.dynamicRealm("test").addProperty(prop4, to: "MyClass", defaultValue: 99)
        try! RLMRealm.dynamicRealm("test").addProperty(prop5, to: "MyClass", defaultValue: NSDate())
    }
    
    func ggg3() {
        let realm = try! RLMRealm.dynamicRealm("test")
        
        realm.beginWriteTransaction()
        let obj = realm.createObject("MyClass", withValue: ["femton", 161, "sjutton", 181, NSDate()])
        realm.addObject(obj)
        try! realm.commitWriteTransaction()
        
        print("Schema #\(realm.configuration.schemaVersion): \(realm.schema)")
        print(realm.allObjects("MyClass"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ggg1()
        ggg2()
        ggg3()
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

