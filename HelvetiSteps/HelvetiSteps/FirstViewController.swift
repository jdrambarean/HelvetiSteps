//
//  FirstViewController.swift
//  HelvetiSteps
//
//  Created by Joseph Drambarean on 2/18/15.
//  Copyright (c) 2015 Joseph Drambarean. All rights reserved.
//

import UIKit
import HealthKit

class FirstViewController: UIViewController {

    let healthKitManager = HealthKitManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestHealthKitAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    @IBOutlet var stepsLabel: UILabel!
    
    //These are the variables for all of the components of the app

    var steps = [HKQuantitySample]()
    
    var stepsToDisplay = 0
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    
    let stepsUnit = HKUnit.countUnit()
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead, completion: { [unowned self] (success, error) in
            if success {
                self.queryStepsSum()
            } else {
                println(error.description)
            }
        })
    }
    
    @IBAction func stepsButton() {
        self.stepsLabel.text = "Loading"
        self.queryStepsSum()
    }
    
    @IBAction func milesButton() {
        self.stepsLabel.text = "Loading"
        self.queryDistanceSum()
    }
    
    func queryStepsSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.stepsUnit))
                self.stepsLabel.text = "\(numberOfSteps)"
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    func queryDistanceSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.distanceCount, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var totalDistance = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.distanceUnit))
                self.stepsLabel.text = "\(totalDistance)"
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
}




extension NSDate {
    func dateByRemovingTime() -> NSDate {
        let flags: NSCalendarUnit = .DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(flags, fromDate: self)
        return calendar.dateFromComponents(components)!
    }
}
