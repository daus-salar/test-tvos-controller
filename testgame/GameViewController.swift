//
//  GameViewController.swift
//  testgame
//
//  Created by lars on 10.10.15.
//  Copyright (c) 2015 LToTheS. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import GameController


class GameViewController: GCEventViewController {
    
    
    var ship : SCNNode!
    var theta : Double = 0
    var phi : Double = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
        
        let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 1)
        scene.rootNode.addChildNode(SCNNode(geometry: cone))
        
        // animate the 3d object
        //ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
//        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        
        print("did appear \(GCController.controllers())")

        
        // add a tap gesture recognizer
        
        controllerUserInteractionEnabled = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didConnectControllerNotification:",
            name: GCControllerDidConnectNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDisconnectControllerNotification:",
            name: GCControllerDidDisconnectNotification, object: nil)
    }
    
    func didConnectControllerNotification(notification: NSNotification) {
        print("Controller did connect \(notification)")
        
        print("\(GCController.controllers())")
        
        if let controller = GCController.controllers().filter({$0.motion != nil}).first  {
            setupController(controller)
        }
    }
    
    func didDisconnectControllerNotification(notification: NSNotification) {
        
        print("\n Controller did disconnent \(notification)")
        
    }
    
    func setupController(controller: GCController) {
        mainController = controller
       
        mainController?.controllerPausedHandler = { controller in
            print("controller did pause \(controller)")
        }
        
        if let motion = mainController?.motion {
            print("found motion profile")
            
            motion.valueChangedHandler = { motion in
                print("gravity \( motion.gravity )")
                print("userAcceleration \( motion.userAcceleration )")
                print("attitude \( motion.attitude )")
                print("rotationRate \( motion.rotationRate )")
                
                let gSize =  sqrt(pow(motion.gravity.x,2) + pow(motion.gravity.y,2) + pow(motion.gravity.z,2))
                self.theta = asin(-motion.attitude.x/gSize)
                let cosTheta = cos(self.theta)
                if  cosTheta > 1E-8 {
                    self.phi = asin(motion.attitude.y / gSize / (cosTheta))
                }
                let theta_2 = self.theta/2
                let phi_2 = self.phi/2
                self.ship.orientation = SCNVector4Make(Float(cos(theta_2) * cos(phi_2)), Float(sin(theta_2) * cos(phi_2)), Float(-sin(theta_2) * sin(phi_2)), Float(cos(theta_2) * sin(phi_2)))
                
            }
        }
        
    }
    
    var mainController: GCController?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(scnView)
        let hitResults = scnView.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject! = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            
            // on completion - unhighlight
            SCNTransaction.setCompletionBlock {
                SCNTransaction.begin()
                SCNTransaction.setAnimationDuration(0.5)
                
                material.emission.contents = UIColor.blackColor()
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.redColor()
            
            SCNTransaction.commit()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
}
