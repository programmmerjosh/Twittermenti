//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let tweetCount:Int = 100
    let sentimentClassifier = TextClassifier()
    
    // located in Secrets.plist
    var consumer_key = ""
    var consumer_secret = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    
    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
        textField.resignFirstResponder()
    }
    
    func fetchTweets() {
        
//        removed keys from Secrets.plist temporarily - this will stop app from working
        consumer_key = getAPIKeyValueFromSecrets(withKey: "API Key")
        consumer_secret = getAPIKeyValueFromSecrets(withKey: "API Secret")
        
        let swifter = Swifter(consumerKey: consumer_key, consumerSecret: consumer_secret)
        
        if let searchText = textField.text {
            
            swifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended, success: { (results, metaData) in
                
                var tweets = [TextClassifierInput]()
                for i in 0..<self.tweetCount {
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TextClassifierInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                self.makePrediction(with: tweets)
            }) { (error) in
                print("There was an error with the Twitter API request, \(error)")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func makePrediction(with input: [TextClassifierInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: input)
            var score:Int = 0
            for prediction in predictions {
                switch prediction.label {
                case "Pos":
                    score += 1
                case "Neg":
                    score -= 1
                default:
                    score += 0
                }
            }
            updateUI(with: score)
        } catch {
            print("There was an error with making a prediction.")
        }
    }
    
    func updateUI(with score: Int) {
        
        sentimentLabel.alpha = 0
        
        UIView.animate(withDuration: 4, animations: {
            if score > 0 {
                self.sentimentLabel.text = "😁"
            } else if score < 0 {
                self.sentimentLabel.text = "😟"
            } else {
                self.sentimentLabel.text = "😐"
            }
            self.sentimentLabel.alpha = 1
        })
    }
    
    func getAPIKeyValueFromSecrets(withKey key: String) -> String {
        
        var plistFormat =  PropertyListSerialization.PropertyListFormat.xml
        
        var plistData: [String: AnyObject] = [:]
        
        let plistPath: String? = Bundle.main.path(forResource: "Secrets", ofType: "plist")!
        
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        
        do {
            // convert data to a dictionary and handle errors.
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &plistFormat) as! [String:AnyObject]
            
            if let value = plistData[key] {
                return value as! String
            }
        } catch {
            print("Error reading plist: \(error), format: \(plistFormat)")
        }
        return ""
    }
}
