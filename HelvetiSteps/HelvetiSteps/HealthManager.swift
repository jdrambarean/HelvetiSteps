//
//  HealthManager.swift
//  HelvetiSteps
//
//  Created by Joseph Drambarean on 2/18/15.
//  Copyright (c) 2015 Joseph Drambarean. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitManager {
    
    class var sharedInstance: HealthKitManager {
        struct Singleton {
            static let instance = HealthKitManager()
        }
        
        return Singleton.instance
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
    
    let stepsUnit = HKUnit.countUnit()
    let distanceUnit = HKUnit(fromString: "mi")
    
    func queryStepsData() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: self.distanceCount, quantitySamplePredicate: predicate, options: nil) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var totalDistance = Int(sumQuantity.doubleValueForUnit(self.distanceUnit))
    
            }
        }
        self.healthStore?.executeQuery(statisticsSumQuery)
    }
}

