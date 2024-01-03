//
//  WelcomeViewController.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/11/23.
//

import UIKit
import AVFAudio

class WelcomeViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var huggingSnoopy: UIImageView!
    
    @IBOutlet weak var textField1: UITextField!
    @IBOutlet weak var textField2: UITextField!
    
    var backgroundAudioPlayer: AVAudioPlayer!
    var backgroundMusicOn = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Set UserDefaults info
        UDM.shared.defaults.set(Consts.player1, forKey: Consts.currentPlayerKey)

        if UDM.shared.defaults.string(forKey: Consts.selectedRedButtonNameKey) == nil {
            UDM.shared.defaults.set(Consts.heart, forKey: Consts.selectedRedButtonNameKey)
        }
        
        if UDM.shared.defaults.string(forKey: Consts.selectedBlueButtonNameKey) == nil {
            UDM.shared.defaults.set(Consts.heart, forKey: Consts.selectedBlueButtonNameKey)
        }
        
        CheckersManager.shared.checkersEngine.initializeGame()
        
        adjustButtonImageSize(settingsButton, Consts.settings)

        initTextFields()
        initBackgroundMusic()
                        
        listenForKeyboardEvents()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapHuggingSnoopy))
        huggingSnoopy.isUserInteractionEnabled = true
        huggingSnoopy.addGestureRecognizer(gesture)
    }
    
    deinit {
        // Stop listening for keyboard hide/show events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func adjustButtonImageSize(_ button: UIButton, _ imageName: String) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        let newImage = UIImage(systemName: imageName, withConfiguration: largeConfig)
        button.setImage(newImage, for: .normal)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
    }
    
    private func initTextFields() {
        textField1.delegate = self
        textField2.delegate = self
        
        if let name1 = UDM.shared.defaults.string(forKey: Consts.nameKeyPlayer1) {
            textField1.text = name1
        }
        if let name2 = UDM.shared.defaults.string(forKey: Consts.nameKeyPlayer2) {
            textField2.text = name2
        }
    }
    
    private func initBackgroundMusic() {
        let url = Bundle.main.url(forResource: "linus-and-lucy", withExtension: "wav")!
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        backgroundAudioPlayer = try? AVAudioPlayer(contentsOf: url)
        backgroundAudioPlayer?.numberOfLoops = -1
        backgroundAudioPlayer?.play()
    }
    
    func listenForKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // Shifts WelcomeVC up/down whenever the keyboard appears/disappears
    @objc func keyboardWillChange(notification: Notification) {
        let key: String = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardRect = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return
        }
        if notification.name == UIResponder.keyboardWillShowNotification ||
             notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }
        
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updatePlayerNamesInUserDefaults()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updatePlayerNamesInUserDefaults()
        self.view.endEditing(true)
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        HapticsManager.shared.selectionVibrate()
        performSegue(withIdentifier: "SettingsSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BeginButtonSegue",
           let vc = segue.destination as? ViewController {
            
            HapticsManager.shared.selectionVibrate()
            
            // ensure there's a reference to the shared `CheckersEngine`
            vc.checkersEngine = CheckersManager.shared.checkersEngine
            
            textField1.resignFirstResponder()
            textField2.resignFirstResponder()
            
            updatePlayerNamesInUserDefaults()
            
            // send player names to `viewController`
            vc.playerName1 = (textField1.text?.isEmpty == false) ? textField1.text : "Player 1"
            vc.playerName2 = (textField2.text?.isEmpty == false) ? textField2.text : "Player 2"
        }
    }
    
    private func updatePlayerNamesInUserDefaults() {
        UDM.shared.defaults.set(textField1.text, forKey: Consts.nameKeyPlayer1)
        UDM.shared.defaults.set(textField2.text, forKey: Consts.nameKeyPlayer2)
    }
    
    // limits the text in UITextFields to be no longer than 16 characters long
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= 16
    }
    
    /*
     Background Music
     */
    @objc func didTapHuggingSnoopy(_ sender: UITapGestureRecognizer) {
        if backgroundMusicOn {
            HapticsManager.shared.selectionVibrate()
            backgroundAudioPlayer?.stop()
            backgroundMusicOn = false
        } else {
            HapticsManager.shared.vibrate(for: .success)
            backgroundAudioPlayer?.play()
            backgroundMusicOn = true
        }
    }
}
