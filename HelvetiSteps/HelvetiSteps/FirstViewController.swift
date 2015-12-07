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
        drawChart()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidLoad()
        requestHealthKitAuthorization()
        querySteps()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    @IBOutlet var valueLabel: UILabel!
    
    
    
    //These are the variables for all of the components of the app

    var steps = [HKQuantitySample]()
    
    var stepsForChart = [HKQuantitySample]()
    
    var stepsInFloat = [CGFloat]()
    
    var label = UILabel()
    var lineChart: LineChart?
    
    var stepsToDisplay = 0
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    
    let stepsUnit = HKUnit.countUnit()
    
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
    
    
    @IBAction func segmentValueChange (sender: AnyObject) {
        if SegmentedControl.selectedSegmentIndex == 0 {
            self.valueLabel.text = ""
            self.queryStepsSum()
            drawChart()
        }
        
        if SegmentedControl.selectedSegmentIndex == 1 {
            self.valueLabel.text = ""
            self.queryDistanceSum()
            drawChart()
        }
    }
    
    

    
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
        label.text = "x: \(x)     y: \(yValues)"
    }
    
    func valueConversion() {
        let floatArray = self.stepsForChart.map({CGFloat($0.quantity.doubleValueForUnit(self.healthKitManager.stepsUnit))})
        self.stepsInFloat = floatArray
    }
    
    func queryStepsSum() {
        self.activity.startAnimating()
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.stepsUnit))
                self.valueLabel.text = "\(numberOfSteps)"
                self.activity.stopAnimating()
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }

    
// This is a future feature that I might want to consider to improve the performance of the app
//    func observerQuerySteps() {
//        self.activity.startAnimating()
//        let startDate = NSDate().dateByRemovingTime()
//        let endDate = NSDate()
//        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: nil)
//        let query = HKObserverQuery(sampleType: steps, predicate: nil) {
//            query, completionHandler, error in
//            if error != nil {
//                
//                // Perform Proper Error Handling Here...
//                println("An error occured")
//                abort()
//            }
//            if let newQuantity = result?.newQuantity() {
//                var totalSteps = Int(newQuantity.doubleValueForUnit(self.healthKitManager.stepsUnit))
//            }
//            }
//    }
    
    
    func queryDistanceSum() {
        self.activity.startAnimating()
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.distanceCount!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                var totalDistance = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.distanceUnit))
                self.valueLabel.text = "\(totalDistance)"
                self.activity.stopAnimating()
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    func querySteps() {
        let sampleQuery = HKSampleQuery(sampleType: healthKitManager.stepsCount!, predicate: nil,
            limit: 100,
            sortDescriptors: nil)
            { [unowned self] (query,results, error) in
                if let results = results as? [HKQuantitySample] {
                    self.stepsForChart = results
                }
        }
        healthKitManager.healthStore?.executeQuery(sampleQuery)
}
    
    func drawChart() {
        var views: Dictionary<String, AnyObject> = [:]
        
        self.label.text = "..."
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.textAlignment = NSTextAlignment.Center
        self.view.addSubview(self.label)
        views["label"] = self.label
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-350-[label]", options: [], metrics: nil, views: views))
        
        let data: Array<CGFloat> = [1, 2, 3, 12, 23, 44, 2, 19, 102, 23]
        //var data2: Array<CGFloat> = [1, 3, 5, 13, 17, 20]
        
        self.lineChart = LineChart()
        self.lineChart!.areaUnderLinesVisible = true
        self.lineChart!.addLine(data)
        //lineChart!.addLine(data2)
        self.lineChart!.translatesAutoresizingMaskIntoConstraints = false
        self.lineChart!.delegate = self
        self.view.addSubview(self.lineChart!)
        views["chart"] = self.lineChart
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==200)]", options: [], metrics: nil, views: views))
        
        let delta: Int64 = 4 * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, delta)
        
        dispatch_after(time, dispatch_get_main_queue(), {
            //self.lineChart!.clear()
            //self.lineChart!.addLine(data2)
        });
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
