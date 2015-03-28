//
//  FirstViewController.swift
//  HelvetiSteps
//
//  Created by Joseph Drambarean on 2/18/15.
//  Copyright (c) 2015 Joseph Drambarean. All rights reserved.
//

import UIKit
import HealthKit

class FirstViewController: UIViewController, LineChartDelegate {

    let healthKitManager = HealthKitManager.sharedInstance
    @IBOutlet var SegmentedControl: UISegmentedControl!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestHealthKitAuthorization()
        //activityIndicator.startAnimating()
        
        var views: Dictionary<String, AnyObject> = [:]
        
        label.text = "..."
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.textAlignment = NSTextAlignment.Center
        self.view.addSubview(label)
        views["label"] = label
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-350-[label]", options: nil, metrics: nil, views: views))
        
        var data: Array<CGFloat> = [3, 4, 9, 11, 13, 15]
        var data2: Array<CGFloat> = [1, 3, 5, 13, 17, 20]
        
        lineChart = LineChart()
        lineChart!.areaUnderLinesVisible = true
        lineChart!.addLine(data)
        lineChart!.addLine(data2)
        lineChart!.setTranslatesAutoresizingMaskIntoConstraints(false)
        lineChart!.delegate = self
        self.view.addSubview(lineChart!)
        views["chart"] = lineChart
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==200)]", options: nil, metrics: nil, views: views))
        
        var delta: Int64 = 4 * Int64(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, delta)
        
        dispatch_after(time, dispatch_get_main_queue(), {
            self.lineChart!.clear()
            self.lineChart!.addLine(data2)
        });
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    @IBOutlet var stepsLabel: UILabel!
    
    
    
    //These are the variables for all of the components of the app

    var steps = [HKQuantitySample]()
    
    var label = UILabel()
    var lineChart: LineChart?
    
    var stepsToDisplay = 0
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    
    let stepsUnit = HKUnit.countUnit()
    
    func requestHealthKitAuthorization() {
        self.activity.startAnimating()
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead, completion: { [unowned self] (success, error) in
            if success {
                self.queryStepsSum()
                self.activity.stopAnimating()
            } else {
                println(error.description)
            }
        })
    }
    
    @IBAction func stepsButton() {
        self.stepsLabel.text = ""
        self.queryStepsSum()
    }
    
    @IBAction func milesButton() {
        self.stepsLabel.text = ""
        self.queryDistanceSum()
    }
    
    @IBAction func segmentValueChange (sender: AnyObject) {
        if SegmentedControl.selectedSegmentIndex == 0 {
            self.stepsLabel.text = ""
            self.queryStepsSum()
        }
        
        if SegmentedControl.selectedSegmentIndex == 1 {
            self.stepsLabel.text = ""
            self.queryDistanceSum()
        }
    }
    
    

    
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
        label.text = "x: \(x)     y: \(yValues)"
    }
    
    func queryStepsSum() {
        activity.startAnimating()
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.stepsUnit))
                self.stepsLabel.text = "\(numberOfSteps)"
                self.activity.stopAnimating()
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    func queryDistanceSum() {
        self.activity.startAnimating()
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.distanceCount, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var totalDistance = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.distanceUnit))
                self.stepsLabel.text = "\(totalDistance)"
                self.activity.stopAnimating()
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
