//
//  ViewController.swift
//  RobotJoystick
//
//  Created by James Asefa on 2017-02-17.
//  Copyright © 2017 James Asefa. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController {
    
    //MARK: instance variables
    var timerTXDelay: Timer?
    var allowTX = true
    var lastPositionx: CGFloat = 255.0
    var lastPositiony: CGFloat = 255.0
    
    //var validTouch: Bool = true
    
    //MARK: Properties

    @IBOutlet var outerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
       _ = btDiscoverySharedInstance
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // print connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    print("Connected!")
                } else {
                    print("Not Connected!")
                }
            }
        });
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: outerView)
            writePosition(position.x,position2: position.y)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: outerView)
            writePosition(position.x,position2: position.y)
        }
    }
    
    // want to send speed of 0 and reset joystick to middle
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.timerTXDelayElapsed()
        writePosition(CGFloat(0.0),position2: CGFloat(0.0))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimerTXDelay()
    }
    
    private func writePosition(_ position1: CGFloat, position2: CGFloat) {
        
        if !allowTX {
            return
        }
        
        if let bleService = btDiscoverySharedInstance.peripheralService {
            
            let xAxis = outerView.frame.width / 2
            let yAxis = outerView.frame.height / 2
            
            // initialize x and y
            var x = CGFloat(0.0)
            var y = CGFloat(0.0)
            
            
            // only convert if we're not writing a touchEnded value
            if (position1 != 0.0 && position2 != 0.0) {
                x = position1 - xAxis // relative to x axis
                y = yAxis - position2 // relative to y axis
            }
            
            print(x)
            print(y)
            
            if (x < 0) {
                bleService.writeLeadingNegativeByteToRobot() 
                x = -x
            }
            
            if (y < 0) {
                bleService.writeLeadingNegativeByteToRobot()
                y = -y
            }
            
            if (x >= 250) {
                x = 250
            }
            
            if (y >= 250) {
                y = 250
            }
            
            bleService.writeToRobot(UInt8(x), positiony: UInt8(y))
            lastPositionx = x;
            lastPositiony = y;
            
            // Start delay timer
            allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.timerTXDelayElapsed), userInfo: nil, repeats: false)
            }
        } else {
            print("nothing from peripheral")
        }
    }
    
    func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
        
        // Send current slider position
        //self.writePosition(0.0, position2: 0.0)
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }
    

}

