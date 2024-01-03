//
//  SettingsViewController.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/11/23.
//

import UIKit
import Photos
import PhotosUI

class SettingsViewController: UIViewController {

    // Switches
    @IBOutlet weak var flipBoardSwitch: UISwitch!
    @IBOutlet weak var oppositeEndsSwitch: UISwitch!
    @IBOutlet weak var timedModeSwitch: UISwitch!
    @IBOutlet weak var snoopyModeSwitch: UISwitch!
    
    // Labels
    @IBOutlet weak var blackLabelPlayer1: UILabel!  // default red
    @IBOutlet weak var blackLabelPlayer2: UILabel!  // default blue
    @IBOutlet weak var redLabelPlayer1: UILabel!    // snoopy
    @IBOutlet weak var blueLabelPlayer2: UILabel!   // woodstock
    
    // Default Checker Piece Buttons
    @IBOutlet weak var heartButton1: UIButton!
    @IBOutlet weak var swirlButton1: UIButton!
    @IBOutlet weak var moonButton1: UIButton!
    @IBOutlet weak var flowerButton1: UIButton!
    @IBOutlet weak var turtleButton1: UIButton!
    @IBOutlet weak var heartButton2: UIButton!
    @IBOutlet weak var swirlButton2: UIButton!
    @IBOutlet weak var moonButton2: UIButton!
    @IBOutlet weak var flowerButton2: UIButton!
    @IBOutlet weak var turtleButton2: UIButton!
    
    // Snoopy/Woodstock Checker Piece Images
    @IBOutlet weak var regularSnoopyImage: UIImageView!
    @IBOutlet weak var kingSnoopyImage: UIImageView!
    @IBOutlet weak var regularWoodstockImage: UIImageView!
    @IBOutlet weak var kingWoodstockImage: UIImageView!
    @IBOutlet weak var redCrownImage: UIImageView!
    @IBOutlet weak var blueCrownImage: UIImageView!
    
    // Miscellaneous
    @IBOutlet weak var merryChristmasLabel: UILabel!
    @IBOutlet weak var snoopySleepingImage: UIImageView!
    
    var redDefaultButtons: [UIButton] = []
    var blueDefaultButtons: [UIButton] = []
    
    var isAnimatingLabel = false // tracks `merryChristmasLabel` animation state

    override func viewDidLoad() {
        super.viewDidLoad()
        
        redDefaultButtons = [heartButton1, swirlButton1, moonButton1, flowerButton1, turtleButton1]
        blueDefaultButtons = [heartButton2, swirlButton2, moonButton2, flowerButton2, turtleButton2]
        
        // adjust image sizing for default checker buttons
        adjustButtonImageSize(heartButton1, Consts.heart)
        adjustButtonImageSize(swirlButton1, Consts.swirl)
        adjustButtonImageSize(moonButton1, Consts.moon)
        adjustButtonImageSize(flowerButton1, Consts.flower)
        adjustButtonImageSize(turtleButton1, Consts.turtle)
        adjustButtonImageSize(heartButton2, Consts.heart)
        adjustButtonImageSize(swirlButton2, Consts.swirl)
        adjustButtonImageSize(moonButton2, Consts.moon)
        adjustButtonImageSize(flowerButton2, Consts.flower)
        adjustButtonImageSize(turtleButton2, Consts.turtle)
        
        retrieveUserDefaultSettings()
                
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapSleepingSnoopy))
        snoopySleepingImage.isUserInteractionEnabled = true
        snoopySleepingImage.addGestureRecognizer(gesture)
    }

    private func adjustButtonImageSize(_ button: UIButton, _ imageName: String) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 29, weight: .regular)
        let newImage = UIImage(systemName: imageName, withConfiguration: largeConfig)
        button.setImage(newImage, for: .normal)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
    }
    
    private func retrieveUserDefaultSettings() {
        let keys = [Consts.flipBoardOnOffKey, 
                    Consts.oppositeEndsOnOffKey,
                    Consts.timerOnOffKey,
                    Consts.snoopyImagesOnOffKey]
        
        // Set switch states
        flipBoardSwitch.setOn(UDM.shared.defaults.bool(forKey: keys[0]), animated: false)
        oppositeEndsSwitch.setOn(UDM.shared.defaults.bool(forKey: keys[1]), animated: false)
        timedModeSwitch.setOn(UDM.shared.defaults.bool(forKey: keys[2]), animated: false)
        snoopyModeSwitch.setOn(UDM.shared.defaults.bool(forKey: keys[3]), animated: false)
        
        // For default checker buttons, set `.isSelected()`
        setSelectedButton(for: redDefaultButtons, key: Consts.selectedRedButtonNameKey)
        setSelectedButton(for: blueDefaultButtons, key: Consts.selectedBlueButtonNameKey)
        
        // Set snoopyMode views on/off
        toggleBottomViews(overlayOn: UDM.shared.defaults.bool(forKey: Consts.snoopyImagesOnOffKey))
    }
    
    private func setSelectedButton(for buttons: [UIButton], key: String) {
        if let systemName = UDM.shared.defaults.string(forKey: key) {
            buttons[0].isSelected = false
            switch systemName {
            case Consts.swirl: buttons[1].isSelected = true
            case Consts.moon: buttons[2].isSelected = true
            case Consts.flower: buttons[3].isSelected = true
            case Consts.turtle: buttons[4].isSelected = true
            default: buttons[0].isSelected = true
            }
        }
    }
    
    @IBAction func didTapRedDefaultCheckerPiece(_ sender: UIButton) {
        let key = Consts.selectedRedButtonNameKey
        handleDefaultButtonPress(for: sender, buttons: redDefaultButtons, key: key)
    }
    
    @IBAction func didTapBlueDefaultCheckerPiece(_ sender: UIButton) {
        let key = Consts.selectedBlueButtonNameKey
        handleDefaultButtonPress(for: sender, buttons: blueDefaultButtons, key: key)
    }
    
    private func handleDefaultButtonPress(for sender: UIButton, buttons: [UIButton], key: String) {
        HapticsManager.shared.selectionVibrate()
        let systemNames = [Consts.heart, Consts.swirl, Consts.moon, Consts.flower, Consts.turtle]
        if let index = buttons.firstIndex(of: sender) {
            buttons.forEach { $0.isSelected = false }
            sender.isSelected = true
            UDM.shared.defaults.set(systemNames[index], forKey: key)
        }
    }
    
    @IBAction func flipBoardSwitchDidChange(_ sender: UISwitch) {
        let isOn = sender.isOn
        if isOn {
            oppositeEndsSwitch.setOn(false, animated: true)
            UDM.shared.defaults.set(false, forKey: Consts.oppositeEndsOnOffKey)
        }
        UDM.shared.defaults.set(sender.isOn, forKey: Consts.flipBoardOnOffKey)
    }
    
    @IBAction func oppositeEndsSwitchDidChange(_ sender: UISwitch) {
        let isOn = sender.isOn
        if isOn {
            flipBoardSwitch.setOn(false, animated: true)
            UDM.shared.defaults.set(false, forKey: Consts.flipBoardOnOffKey)
        }
        UDM.shared.defaults.set(sender.isOn, forKey: Consts.oppositeEndsOnOffKey)
    }
    
    @IBAction func timedModeSwitchDidChange(_ sender: UISwitch) {
        UDM.shared.defaults.set(sender.isOn, forKey: Consts.timerOnOffKey)
    }
    
    @IBAction func snoopyImagesSwitchDidChange(_ sender: UISwitch) {
        toggleBottomViews(overlayOn: sender.isOn)
        UDM.shared.defaults.set(sender.isOn, forKey: Consts.snoopyImagesOnOffKey)
    }
    
    private func toggleBottomViews(overlayOn: Bool) {
        // Snoopy Mode OFF
        blackLabelPlayer1.isHidden = overlayOn
        blackLabelPlayer2.isHidden = overlayOn
        heartButton1.isHidden = overlayOn
        swirlButton1.isHidden = overlayOn
        moonButton1.isHidden = overlayOn
        flowerButton1.isHidden = overlayOn
        heartButton2.isHidden = overlayOn
        swirlButton2.isHidden = overlayOn
        moonButton2.isHidden = overlayOn
        flowerButton2.isHidden = overlayOn
        turtleButton1.isHidden = overlayOn
        turtleButton2.isHidden = overlayOn
        // Snoopy Mode ON
        redLabelPlayer1.isHidden = !overlayOn
        blueLabelPlayer2.isHidden = !overlayOn
        snoopySleepingImage.isHidden = !overlayOn
        regularSnoopyImage.isHidden = !overlayOn
        kingSnoopyImage.isHidden = !overlayOn
        regularWoodstockImage.isHidden = !overlayOn
        kingWoodstockImage.isHidden = !overlayOn
        redCrownImage.isHidden = !overlayOn
        blueCrownImage.isHidden = !overlayOn
    }
    
    /*
     Animation
     */
    @objc func didTapSleepingSnoopy(_ sender: UITapGestureRecognizer) {
        guard !isAnimatingLabel else {
            return
        }
        
        HapticsManager.shared.selectionVibrate()
                
        isAnimatingLabel = true
        snoopyModeSwitch.isUserInteractionEnabled = false
        
        // Set the initial scale and alpha for the label
        merryChristmasLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        merryChristmasLabel.alpha = 0.0
        merryChristmasLabel.isHidden = false
        
        UIView.animate(
            withDuration: 1.75,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                // animate the label to grow in size and fade in
                self.merryChristmasLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.merryChristmasLabel.alpha = 1.0
            },
            completion: { _ in
                // after the animation completes, fade out the label
                UIView.animate(
                    withDuration: 0.35,
                    delay: 1.4,
                    options: .curveEaseOut,
                    animations: {
                        self.merryChristmasLabel.alpha = 0.0
                    },
                    completion: { _ in
                        // hide the label after it fades out
                        self.merryChristmasLabel.isHidden = true
                        // reset label properties for future animations
                        self.merryChristmasLabel.transform = CGAffineTransform.identity
                        // unlock locks
                        self.isAnimatingLabel = false
                        self.snoopyModeSwitch.isUserInteractionEnabled = true
                    }
                )
            }
        )
    }
}
