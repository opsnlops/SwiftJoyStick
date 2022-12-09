//
//  main.swift
//  SwiftJoyStick
//
//  Created by April White on 12/8/22.
//


/*
    This is full of example code from Apple. I'm learning how this stuff works!
 */

import Foundation
import GameController

// Game Controller Properties
private var gamePadCurrent: GCController?
private var gamePadLeft: GCControllerDirectionPad?
private var gamePadRight: GCControllerDirectionPad?


func handleControllerDidConnect(_ notification: Notification) {
    guard let gameController = notification.object as? GCController else {
        return
    }
    unregisterGameController()
    
#if os( iOS )
    if #available(iOS 15.0, *) {
        if gameController != virtualController?.controller {
            virtualController?.disconnect()
        }
    }
#endif
    
    registerGameController(gameController)

}



func setupGameController() {
    if #available(iOS 14.0, OSX 10.16, *) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMouseDidConnect),
                                               name: NSNotification.Name.GCMouseDidBecomeCurrent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMouseDidDisconnect),
                                               name: NSNotification.Name.GCMouseDidStopBeingCurrent, object: nil)
        if let mouse = GCMouse.mice().first {
            registerMouse(mouse)
        }
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardDidConnect),
                                           name: NSNotification.Name.GCKeyboardDidConnect, object: nil)
    
    NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleControllerDidConnect),
            name: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil)

    NotificationCenter.default.addObserver(
        self, selector: #selector(self.handleControllerDidDisconnect),
        name: NSNotification.Name.GCControllerDidStopBeingCurrent, object: nil)
    
#if os( iOS )
    if #available(iOS 15.0, *) {
        let virtualConfiguration = GCVirtualController.Configuration()
        virtualConfiguration.elements = [GCInputLeftThumbstick,
                                         GCInputRightThumbstick,
                                         GCInputButtonA,
                                         GCInputButtonB]
        virtualController = GCVirtualController(configuration: virtualConfiguration)
        
        // Connect to the virtual controller if no physical controllers are available.
        if GCController.controllers().isEmpty {
            virtualController?.connect()
        }
    }
#endif
    
    guard let controller = GCController.controllers().first else {
        return
    }
    registerGameController(controller)
}


func registerGameController(_ gameController: GCController) {

    var buttonA: GCControllerButtonInput?
    var buttonB: GCControllerButtonInput?
    var rightTrigger: GCControllerButtonInput?

    weak var weakController = self
    
    if let gamepad = gameController.extendedGamepad {
        self.gamePadLeft = gamepad.leftThumbstick
        self.gamePadRight = gamepad.rightThumbstick
        buttonA = gamepad.buttonA
        buttonB = gamepad.buttonB
        rightTrigger = gamepad.rightTrigger
    } else if let gamepad = gameController.microGamepad {
        self.gamePadLeft = gamepad.dpad
        buttonA = gamepad.buttonA
        buttonB = gamepad.buttonX
    }
    
    buttonA?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
        guard let strongController = weakController else {
            return
        }
        strongController.controllerJump(pressed)
    }

    buttonB?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
        guard let strongController = weakController else {
            return
        }
        strongController.controllerAttack()
    }
    
    rightTrigger?.pressedChangedHandler = buttonB?.valueChangedHandler

#if os( iOS )
if gamePadLeft != nil {
        overlay!.hideVirtualPad()
    }
#endif
}

func unregisterGameController() {
    gamePadLeft = nil
    gamePadRight = nil
    gamePadCurrent = nil
#if os( iOS )
    overlay!.showVirtualPad()
#endif
}


