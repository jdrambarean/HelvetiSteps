//
//  GlanceController.swift
//  HelvetiSteps Watch Extension
//
//  Created by Drambarean, Joseph on 1/26/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class GlanceController: WKInterfaceController {
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        queryStepsSum()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        queryStepsSum()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateStepsCountLabel() {
        queryStepsSum()
    }
    
        let healthStore: HKHealthStore? = {
            if HKHealthStore.isHealthDataAvailable() {
                return HKHealthStore()
            } else {
                return nil
            }
        }()
        
    @IBOutlet var stepsCountLabel: WKInterfaceLabel!
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    let distanceCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
    let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    let activeCalories = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
    let stepsUnit = HKUnit.countUnit()
    let distanceUnit = HKUnit(fromString: "mi")
    let heartRateUnit = HKUnit(fromString: "count/min")
    let activeCaloriesUnit = HKUnit(fromString: "kcal")
    var steps = [HKQuantitySample]()
    
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
        let statisticsSumQuery = HKStatisticsQuery(quantityType: self.stepsCount!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                dispatch_async(dispatch_get_main_queue(), {
                    let numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.stepsUnit))
                    self.stepsCountLabel.setText("\(numberOfSteps)")
                })
            }
            
        }
        self.healthStore?.executeQuery(statisticsSumQuery)
    }


}


extension NSDate {
    func dateByRemovingTime() -> NSDate {
        let flags: NSCalendarUnit = [.NSDayCalendarUnit, .NSMonthCalendarUnit, .NSYearCalendarUnit]
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(flags, fromDate: self)
        return calendar.dateFromComponents(components)!
    }
}


