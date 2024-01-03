//
//  ViewController.swift
//  Checkers
//
//  Created by Gabriel Casanova on 12/4/23.
//

import UIKit
import AVFoundation
import MultipeerConnectivity

class ViewController: UIViewController {
        
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var topSafeAreaConstraint: NSLayoutConstraint!
    @IBOutlet weak var horizontalCenterConstraint: NSLayoutConstraint!
    
    // Used when "Opposite Ends Mode" is turned on, hints at which player's turn it is
    @IBOutlet weak var pufferSnoopyPlayer1: UIImageView!
    @IBOutlet weak var pufferSnoopyPlayer2: UIImageView!
    
    var checkersEngine: CheckersEngine!
    var dropAudioPlayer: AVAudioPlayer!
    
    // Multipeer Connectivity
    var peerID: MCPeerID!
    var session: MCSession!
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    
    // player names
    var playerName1: String!
    var playerName2: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init AudioPlayer
        let url = Bundle.main.url(forResource: "drop", withExtension: "wav")!
        dropAudioPlayer = try? AVAudioPlayer(contentsOf: url)
        
        initMultipeerConnectivity()
        
        // programatically rotate player 2's snoopy puffer image
        pufferSnoopyPlayer2.image = pufferSnoopyPlayer2.image?.rotated180Degrees()
                
        let oppositeEndsOn = UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey)
        let currentPlayer = UDM.shared.defaults.string(forKey: Consts.currentPlayerKey)!
        
        // initialize InfoLabel
        let playerName = (currentPlayer == Consts.player1) ? playerName1 : playerName2
        infoLabel.text = "\(playerName!)'s Turn"
        infoLabel.isHidden = oppositeEndsOn
        
        if checkersEngine.gameOver() {
            let winner: String = checkersEngine.player1Turn ? playerName2 : playerName1
            infoLabel.text = "Game Over! \(winner) won :)"
        }
        
        if oppositeEndsOn {
            let isPlayer1 = (currentPlayer == Consts.player1)
            pufferSnoopyPlayer1.isHidden = !isPlayer1
            pufferSnoopyPlayer2.isHidden = isPlayer1
        }
        
        boardView.checkersDelegate = self
        initBoardViewConstraints()
        
        // initialize CheckersEngine
        checkersEngine = CheckersManager.shared.checkersEngine
        if checkersEngine.pieces.isEmpty {
            checkersEngine.initializeGame()
        } else {
            // default vs. snoopy
            setCheckerPieceSources()
        }
        boardView.shadowPieces = checkersEngine.pieces
        boardView.setNeedsDisplay()
    }
    
    private func setCheckerPieceSources() {
        if UDM.shared.defaults.bool(forKey: Consts.snoopyImagesOnOffKey) {
            for piece in checkersEngine.pieces {
                setSnoopyCheckerSource(piece: piece)
            }
        } else {
            let systemName1 = UDM.shared.defaults.string(forKey: Consts.selectedRedButtonNameKey)!
            let systemName2 = UDM.shared.defaults.string(forKey: Consts.selectedBlueButtonNameKey)!
            for piece in checkersEngine.pieces {
                setSystemNameCheckerSource(piece: piece, systemName1, systemName2)
            }
        }
    }
    
    private func setSnoopyCheckerSource(piece: CheckerPiece) {
        var imageName: String
        switch (piece.player, piece.type) {
            case (.player1, .regular):
                imageName = Consts.snoopyRegular
            case (.player1, .king):
                imageName = Consts.snoopyKing
            case (.player2, .regular):
                imageName = Consts.woodstockRegular
            case (.player2, .king):
                imageName = Consts.woodstockKing
        }
        let source: ImageSource = .image(UIImage(named: imageName)!)
        checkersEngine.pieces.remove(piece)
        checkersEngine.pieces.insert(CheckerPiece(col: piece.col, row: piece.row, color: piece.color, type: piece.type, source: source, player: piece.player))
    }
    
    private func setSystemNameCheckerSource(piece: CheckerPiece, _ name1: String, _ name2: String) {
        var systemName: String
        if piece.type == .king {
            systemName = Consts.king
        } else {
            systemName = (piece.player == .player1) ? name1 : name2
        }
        let source: ImageSource = .systemName(systemName)
        checkersEngine.pieces.remove(piece)
        checkersEngine.pieces.insert(CheckerPiece(col: piece.col, row: piece.row, color: piece.color, type: piece.type, source: source, player: piece.player))
    }
    
    private func initBoardViewConstraints() {
        let horizontalCenterOn = UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey)
        topSafeAreaConstraint.isActive = !horizontalCenterOn
        horizontalCenterConstraint.isActive = horizontalCenterOn
    }
    
    @IBAction func didTapTrashCanButton(_ sender: Any) {
        
        HapticsManager.shared.vibrate(for: .success)
        
        let controller = UIAlertController(title: "Reset Game",
                                           message: "Would you like to start a new game?",
                                           preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.resetGame()
        }

        controller.addAction(cancelAction)
        controller.addAction(resetAction)

        present(controller, animated: true)
    }
    
    private func resetGame() {
        checkersEngine.initializeGame()
        boardView.shadowPieces = checkersEngine.pieces
        boardView.setNeedsDisplay()  // trigger repaint
        
        infoLabel.text = "\(playerName1!)'s Turn"
        UDM.shared.defaults.set(Consts.player1, forKey: Consts.currentPlayerKey)
        
        if UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey) {
            pufferSnoopyPlayer1.isHidden = false
            pufferSnoopyPlayer2.isHidden = true
        }
        
        // Update the shared CheckersEngine in the CheckersManager
        CheckersManager.shared.checkersEngine = checkersEngine
    }
    
    /*
     Multipeer Connectivity [UNUSED]
     */
    private func initMultipeerConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.name)  // "Gabriel's iPhone"
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    @IBAction func advertise(_ sender: Any) {
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "checkers")
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceAdvertiser.startAdvertisingPeer()
        boardView.setNeedsDisplay()
    }
    
    @IBAction func join(_ sender: Any) {
        let browser = MCBrowserViewController(serviceType: "checkers", session: session)
        browser.delegate = self
        present(browser, animated: true)
    }
}

/*
 `CheckersDelegate` Implementation
 */
extension ViewController: CheckersDelegate {
    
    func movePiece(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) {
        // update board on the GameEngine
        updateMove(fromCol: fromCol, fromRow: fromRow, toCol: toCol, toRow: toRow)
        
        // send movement data to peer
        let move: String = "\(fromCol):\(fromRow):\(toCol):\(toRow)"
        if let data = move.data(using: .utf8) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
    
    func updateMove(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) {
        let success = checkersEngine.movePiece(fromCol: fromCol, fromRow: fromRow, toCol: toCol, toRow: toRow)
        boardView.shadowPieces = checkersEngine.pieces
        boardView.setNeedsDisplay()
                
        if !success {
            HapticsManager.shared.vibrate(for: .warning)
        } else {
            HapticsManager.shared.vibrate(for: .success)
            DispatchQueue.main.async {
                self.dropAudioPlayer.play()
            }
            
            // check if the player can perform a double jump
            let piece = pieceAt(col: toCol, row: toRow)!
            let canDoubleJump = checkersEngine.canDoubleJump(using: piece)
            let skipDoubleJump = checkersEngine.skipDoubleJump ?? false
            
            if !canDoubleJump || skipDoubleJump {
                checkersEngine.resetDoubleJumpVariables()
                checkersEngine.player1Turn.toggle()
                if UDM.shared.defaults.bool(forKey: Consts.oppositeEndsOnOffKey) {
                    pufferSnoopyPlayer1.isHidden = !checkersEngine.player1Turn
                    pufferSnoopyPlayer2.isHidden = checkersEngine.player1Turn
                }
            }
        }
        
        if checkersEngine.gameOver() {
            let winner: String = checkersEngine.player1Turn ? playerName2 : playerName1
            infoLabel.text = "Game Over! \(winner) won :)"
        } else {
            let currentPlayer = checkersEngine.player1Turn ? Consts.player1 : Consts.player2
            let playerName = checkersEngine.player1Turn ? playerName1 : playerName2
            UDM.shared.defaults.set(currentPlayer, forKey: Consts.currentPlayerKey)
            infoLabel.text = "\(playerName!)'s Turn"
        }
        
        // Update the shared CheckersEngine in the CheckersManager
        CheckersManager.shared.checkersEngine = checkersEngine
    }
    
    func pieceAt(col: Int, row: Int) -> CheckerPiece? {
        return checkersEngine.pieceAt(col: col, row: row)
    }
}

/*
 sending advertisement
 */
extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

/*
 building communication (inviting/broadcasting connection to join), negotiating b/w two peers
 */
extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}

/*
 communication channel
 */
extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("connected: \(peerID.displayName)")
        case .connecting:
            print("connecting: \(peerID.displayName)")
        case .notConnected:
            print("not connected: \(peerID.displayName)")
        @unknown default:
            fatalError()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("received data: \(data)")
        if let move = String(data: data, encoding: .utf8) {
            // fromCol:fromRow:toCol:toRow
            let arr = move.components(separatedBy: ":")
            if let fromCol = Int(arr[0]), let fromRow = Int(arr[1]), let toCol = Int(arr[2]), let toRow = Int(arr[3]) {
                DispatchQueue.main.async {
                    // update the UI
                    self.updateMove(fromCol: fromCol, fromRow: fromRow, toCol: toCol, toRow: toRow)
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
