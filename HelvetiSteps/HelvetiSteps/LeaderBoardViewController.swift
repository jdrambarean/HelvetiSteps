//
//  LeaderBoardViewController.swift
//  HelvetiSteps
//
//  Created by Drambarean, Joseph on 1/21/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import GameKit

class LeaderBoardViewController: UIViewController, GKGameCenterControllerDelegate {
    
    let healthKitManager = HealthKitManager.sharedInstance
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateLocalPlayer()
        //showLeaderboard()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidLoad()
        self.authenticateLocalPlayer()
        showLeaderboard()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.lineChart?.clear()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func refreshView(sender: AnyObject) {
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
    
    
    
    func showLeaderboard() {
        let gcVC: GKGameCenterViewController = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = GKGameCenterViewControllerState.Leaderboards
        gcVC.leaderboardIdentifier = "STPL"
        self.presentViewController(gcVC, animated: true, completion: nil)
    }
    
    @IBAction func viewLeaderBoard(sender: AnyObject) {
        showLeaderboard()
    }
}
