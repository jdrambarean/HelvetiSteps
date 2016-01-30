//
//  TodayViewController.swift
//  HelvetiStepsWidget
//
//  Created by Drambarean, Joseph on 1/26/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import UIKit
import NotificationCenter
import HealthKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    let healthKitManager = HealthKitManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateStepsCountLabel()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        widgetPerformUpdateWithCompletionHandler { (NCUpdateResult) -> Void in
            self.updateStepsCountLabel()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        requestHealthKitAuthorization()
        
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    @IBOutlet weak var stepsCountLabel: UILabel!
    
    func updateStepsCountLabel() {
        requestHealthKitAuthorization()
    }
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount!, healthKitManager.distanceCount!)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead as NSSet as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
                self.queryStepsSum()
                //self.querySteps()
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
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                dispatch_async(dispatch_get_main_queue(), {
                    let numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.stepsUnit))
                    self.stepsCountLabel.text = "\(numberOfSteps)"
                })
            }
            
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
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

