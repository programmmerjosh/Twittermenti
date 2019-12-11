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
    
    let swifter = Swifter(consumerKey: "WexsmeMBm1nB78utLQXz4njek", consumerSecret: "vZvbemc9vJZQY1WkxgPOoC3as3dwsjaEJXm3hgPO3YH1frLN8J")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    
    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
        textField.resignFirstResponder()
    }
    
    func fetchTweets() {
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
}
