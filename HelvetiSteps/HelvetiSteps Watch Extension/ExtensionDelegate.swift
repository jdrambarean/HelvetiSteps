//
//  ExtensionDelegate.swift
//  HelvetiSteps Watch Extension
//
//  Created by Drambarean, Joseph on 1/26/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import WatchKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        queryStepsSum()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        queryStepsSum()
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        
        queryStepsSum()
    }
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    let distanceCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
    let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    let activeCalories = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
    let stepsUnit = HKUnit.countUnit()
    let distanceUnit = HKUnit(fromString: "mi")
    let heartRateUnit = HKUnit(fromString: "count/min")
    let activeCaloriesUnit = HKUnit(fromString: "kcal")
    var steps = [HKQuantitySample]()
    var calculatedSteps = 0
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: stepsCount!, distanceCount!)
        healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead as NSSet as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
                self.queryStepsSum()
            } else {
                print(error!.description)
            }
            })
    }
    
    func queryStepsSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        print("1")
        let statisticsSumQuery = HKStatisticsQuery(quantityType: self.stepsCount!, quantitySamplePredicate: predicate, options: sumOption){ [unowned self] (query, result, error) in
            if let sumQuantity = result!.sumQuantity() {
                print("2")
                dispatch_async(dispatch_get_main_queue(), {
                    print("3")
                    let numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.stepsUnit))
                    self.calculatedSteps = numberOfSteps
                    print("success")
                })
            }
            
        }
        print("4")
        self.healthStore?.executeQuery(statisticsSumQuery)
    }
    

}
