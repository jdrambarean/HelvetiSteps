//
//  Steps.swift
//  HelvetiSteps
//
//  Created by Drambarean, Joseph on 1/11/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import GameKit

class StepsViewController: UIViewController, LineChartDelegate, GKGameCenterControllerDelegate {
    
    let healthKitManager = HealthKitManager.sharedInstance
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lineChart?.clear()
        requestHealthKitAuthorization()
        self.authenticateLocalPlayer()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidLoad()
        self.lineChart?.clear()
        requestHealthKitAuthorization()
        self.authenticateLocalPlayer()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.lineChart?.clear()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func refreshView(sender: AnyObject) {
        self.queryStepsSum()
        self.getDataArray()
    }
    
    @IBOutlet var valueLabel: UILabel!
    
    @IBOutlet var chartView: UIContentContainer!
    
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
    
    var score = 0
    
    var gcEnabled = Bool()
    
    var gcdefaultLeaderBoard = String()
    
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
    
    func submitScore() {
        let leaderboardID = "STPL"
        let sScore = GKScore(leaderboardIdentifier: leaderboardID)
        sScore.value = Int64(self.score)
        
        GKScore.reportScores([sScore], withCompletionHandler: { (error: NSError?) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Score submitted")
                
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
                self.valueLabel.text = "\(numberOfSteps)"
                self.score = numberOfSteps
                self.submitScore()
                })
        }

    }
        healthKitManager.healthStore?.executeQuery(statisticsSumQuery)
    }
    
    
    func getDataArray() {
        self.activity.startAnimating()
        let stepsCount = HKQuantityType.quantityTypeForIdentifier(
            HKQuantityTypeIdentifierStepCount)
        
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        
        let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount!,
            predicate: predicate,
            limit: 500,
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
                    else { self.chartData = results.map {$0.quantity.doubleValueForUnit(HealthKitManager.sharedInstance.stepsUnit)}
                        self.drawChart()
                        }})
                }
        }
        
        healthKitManager.healthStore?.executeQuery(stepsSampleQuery)
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
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==150)]", options: [], metrics: nil, views: views))
        
        let delta: Int64 = 4 * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, delta)
        
        dispatch_after(time, dispatch_get_main_queue(), {
            //self.lineChart!.clear()
            //self.lineChart!.addLine(data2)
        });
        
        self.activity.stopAnimating()
    }
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1 Show login if player is not logged in
                self.presentViewController(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.authenticated) {
                // 2 Player is already euthenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({ (leaderboardIdentifer: String?, error: NSError?) -> Void in
                    if error != nil {
                        print(error)
                    } else {
                        self.gcdefaultLeaderBoard = leaderboardIdentifer!
                    }
                })
                
                
            } else {
                // 3 Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated, disabling game center")
                print(error)
            }
            
        }
        
    }
    
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func showLeaderboard(sender: UIButton) {
        let gcVC: GKGameCenterViewController = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = GKGameCenterViewControllerState.Leaderboards
        gcVC.leaderboardIdentifier = "STPL"
        self.presentViewController(gcVC, animated: true, completion: nil)
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
