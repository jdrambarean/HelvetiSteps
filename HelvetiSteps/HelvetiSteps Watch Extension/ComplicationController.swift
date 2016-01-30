//
//  ComplicationController.swift
//  HelvetiSteps Watch Extension
//
//  Created by Drambarean, Joseph on 1/26/16.
//  Copyright © 2016 Joseph Drambarean. All rights reserved.
//

import ClockKit
import HealthKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
    let distanceCount = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
    let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    let activeCalories = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
    let stepsUnit = HKUnit.countUnit()
    let distanceUnit = HKUnit(fromString: "mi")
    let heartRateUnit = HKUnit(fromString: "count/min")
    let activeCaloriesUnit = HKUnit(fromString: "kcal")
    var steps = [HKQuantitySample]()
    var calculatedSteps = 0
    
    
    func queryStepsSum() {
        let sumOption = HKStatisticsOptions.CumulativeSum
        let startDate = NSDate().dateByRemovingTime()
        let endDate = NSDate()
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: [])
        print("1")
        let statisticsSumQuery = HKStatisticsQuery(quantityType: stepsCount!, quantitySamplePredicate: predicate, options: sumOption){ [unowned self] (query, result, error) in
            if let sumQuantity = result!.sumQuantity() {
                print("2")
                dispatch_async(dispatch_get_main_queue(), {
                    print("3")
                    let numberOfSteps = Int(sumQuantity.doubleValueForUnit(self.stepsUnit))
                    self.calculatedSteps = numberOfSteps
                    let prefs = NSUserDefaults.standardUserDefaults()
                    prefs.setValue(self.calculatedSteps, forKey: "calculatedSteps")
                    prefs.synchronize()
                    print("success")
                })
            }
            
        }
        print("4")
        healthStore?.executeQuery(statisticsSumQuery)
    }
    
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        self.queryStepsSum()
        let prefs = NSUserDefaults.standardUserDefaults()
        let stepsData = prefs.integerForKey("calculatedSteps")
        calculatedSteps = stepsData
        
        if complication.family == .UtilitarianLarge {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "\(calculatedSteps) Steps")
            
            let timeLineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            
        handler(timeLineEntry)
        }
        
        if complication.family == .ModularLarge {
            let template = CLKComplicationTemplateModularLargeTallBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Steps")
            template.bodyTextProvider = CLKSimpleTextProvider(text: "\(calculatedSteps)")
            
            let timeLineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            handler(timeLineEntry)
        } else {
            handler(nil)
        }
        
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler([])
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(NSDate(timeIntervalSinceNow: 15))
        self.queryStepsSum()
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .ModularSmall:
            template = nil
        case .ModularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTallBody()
            modularTemplate.bodyTextProvider = CLKSimpleTextProvider(text: "Loading")
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Steps")
            template = modularTemplate
        case .UtilitarianSmall:
            template = nil
        case .UtilitarianLarge:
            let utilitarianLargeTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilitarianLargeTemplate.textProvider = CLKSimpleTextProvider(text: "Loading")
            template = utilitarianLargeTemplate
        case .CircularSmall:
            template = nil
        }
        handler(template)
    }
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    
}
