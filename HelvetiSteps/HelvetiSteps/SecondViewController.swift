//
//  SecondViewController.swift
//  HelvetiSteps
//
//  Created by Joseph Drambarean on 2/18/15.
//  Copyright (c) 2015 Joseph Drambarean. All rights reserved.
//

import UIKit
import HealthKit

class SecondViewController: UIViewController {
    
    let healthKitManager = HealthKitManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHealthKitAuthorization()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet var milesLabel: UILabel!
    
    //These are the variables for all of the components of the app
    
    var distance = [HKQuantitySample]()
    
    var distanceToDisplay = 0
    
    let distanceCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
    
    let distanceUnit = HKUnit.countUnit()
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.distanceCount)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead, completion: { [unowned self] (success, error) in
            if success {
                self.queryDistanceSum()
            } else {
                println(error.description)
            }
        })
    }
    
    
    func queryDistanceSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.distanceCount, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var totalDistance = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.distanceUnit))
                self.milesLabel.text = "\(totalDistance)"
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }


}
