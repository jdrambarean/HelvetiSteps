//
//  ActiveEnergy.swift
//  HelvetiSteps
//
//  Created by Drambarean, Joseph on 1/11/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import Foundation

import UIKit
import HealthKit

class ActiveEnergyViewController: UIViewController, LineChartDelegate {
    
    let healthKitManager = HealthKitManager.sharedInstance
    
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
    
    @IBAction func refreshView(sender: AnyObject) {
        self.queryActiveCaloriesSum()
        self.getDataArray()
    }
    
    
    //These are the variables for all of the components of the app
    
    
    var stepsForChart = [HKQuantitySample]()
    
    var stepsInFloat = [CGFloat]()
    
    var label = UILabel()
    var lineChart: LineChart?
    
    var stepsToDisplay = 0
    
    var chartData = []
    
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.activeCalories!)
        healthKitManager.healthStore?.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead as NSSet as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
                self.queryActiveCaloriesSum()
                self.getDataArray()
            } else {
                print(error!.description)
            }
            })
    }
    
    func queryActiveCaloriesSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.activeCalories!, quantitySamplePredicate: predicate, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                dispatch_async(dispatch_get_main_queue(), {
                let totalCalories = Int(sumQuantity.doubleValueForUnit(self.healthKitManager.activeCaloriesUnit))
                self.valueLabel.text = "\(totalCalories)"
            })
            }
        }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    
    
    func getDataArray() {
        self.activity.startAnimating()
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        
        let calorieSampleQuery = HKSampleQuery(sampleType: HealthKitManager.sharedInstance.activeCalories!,
            predicate: predicate,
            limit: 100,
            sortDescriptors: nil)
            { [unowned self] (query, results, error) in
                if let results = results as? [HKQuantitySample] {
                    dispatch_async(dispatch_get_main_queue(), {
                    if results == [] {
                        let alert = UIAlertController(title: "Oops", message: "It looks like you don't have any data recorded for this category", preferredStyle: .Alert)
                        let cancelAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .Cancel) { action -> Void in
                            self.chartData = [0,0,0,0,0,0,0,0]
                            self.drawChart()
                        }
                        alert.addAction(cancelAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    else { self.chartData = results.map {$0.quantity.doubleValueForUnit(HealthKitManager.sharedInstance.activeCaloriesUnit)}
                        self.drawChart()
                    }
                    })
                }
        }
        
        healthKitManager.healthStore?.executeQuery(calorieSampleQuery)
    }
    
    
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
        label.text = "x: \(x)     y: \(yValues)"
    }
    
    func drawChart() {
        self.activity.startAnimating()
        self.lineChart?.clear()

        var views: Dictionary<String, AnyObject> = [:]
        
        self.label.text = "..."
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.textAlignment = NSTextAlignment.Center
        self.view.addSubview(self.label)
        views["label"] = self.label
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-400-[label]", options: [], metrics: nil, views: views))
        
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
        
        self.activity.stopAnimating()
    }
    
}