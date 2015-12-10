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
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidLoad()
        requestHealthKitAuthorization()
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
    
    var chartData = []
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    
    let stepsUnit = HKUnit.countUnit()
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount!, healthKitManager.distanceCount!)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead as NSSet as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
                self.queryStepsSum()
                self.getDataArray()
                //self.querySteps()
            } else {
                print(error!.description)
            }
        })
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
    
    
    
    func queryDistanceSum() {
        self.activity.startAnimating()
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.distanceCount!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let totalDistance = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.distanceUnit))
                self.valueLabel.text = "\(totalDistance)"
                self.activity.stopAnimating()
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    func getDataArray() {
        self.activity.startAnimating()
        let stepsCount = HKQuantityType.quantityTypeForIdentifier(
            HKQuantityTypeIdentifierStepCount)
        
        let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount!,
            predicate: nil,
            limit: 100,
            sortDescriptors: nil)
            { [unowned self] (query, results, error) in
                if let results = results as? [HKQuantitySample] {
                    let dataArray = results.map {$0.quantity.doubleValueForUnit(self.stepsUnit)}
                    self.chartData = dataArray
                    self.drawChart()
                    self.activity.stopAnimating()
                }
        }
        
        healthKitManager.healthStore?.executeQuery(stepsSampleQuery)
    }
    
    
//    @IBAction func segmentValueChange (sender: AnyObject) {
//        if SegmentedControl.selectedSegmentIndex == 0 {
//            self.valueLabel.text = ""
//            self.queryStepsSum()
//            self.getDataArray()
//        }
//        
//        if SegmentedControl.selectedSegmentIndex == 1 {
//            self.valueLabel.text = ""
//            self.queryDistanceSum()
//            self.getDataArray()
//        }
//    }
    
    

    
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
        label.text = "x: \(x)     y: \(yValues)"
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
        
        let data: Array<CGFloat> = chartData as! Array<CGFloat>
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
