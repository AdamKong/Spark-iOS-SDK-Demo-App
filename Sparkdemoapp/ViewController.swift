//
//  ViewController.swift
//  Sparkdemoapp
//
//  Created by adkong on 9/5/2017.
//  Copyright © 2017 adkong. All rights reserved.
//

import UIKit
import SparkSDK

class ViewController: UIViewController, UITextFieldDelegate {
    
    var spark :Spark?
    var authenticator:OAuthAuthenticator?
    let supportRepEmail = "support@your_domain.com"
    
    let clientId = "your_clientId"
    let clientSecret = "your{_clientSecret"
    let scope = "spark:all"
    let redirectUri = "Sparkdemoapp://response"
    
    //outlets
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var textSupportLabel: UILabel!
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var createRoomButton: UIButton!
    @IBOutlet weak var roomSuccessLabel: UILabel!
    
    @IBOutlet weak var line1: UILabel!
    
    @IBOutlet weak var audioVideoSupportLabel: UILabel!
    
    @IBOutlet weak var callSalesTeam: UIButton!
    @IBOutlet weak var callSupportTeam: UIButton!
    @IBOutlet weak var callBillingTeam: UIButton!
    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var callerLabel: UILabel!
    @IBOutlet weak var callerView: MediaRenderView!
    @IBOutlet weak var calledLabel: UILabel!
    @IBOutlet weak var calledView: MediaRenderView!
    
    @IBOutlet weak var signInPrompt: UILabel!
    
    
    //actions
    //create a room with a user clicks the "create a room" button
    @IBAction func createRoom(_ sender: Any) {
        
        roomName.isHidden = true
        createRoomButton.isHidden = true
        roomSuccessLabel.isHidden = false
        roomSuccessLabel.text = "Creating a room, please wait!"
        
        var roomTitle:String?
        if roomName.text == nil || roomName.text == "" {
            roomTitle = "Help Room"
        } else {
            roomTitle = roomName.text!
        }
        print("room title is: \(roomTitle!)")
        
        // Create a new room
        spark!.rooms.create(title: roomTitle!){ response in
            switch response.result {
            case .success(let ro):
                print("\(ro.title!), created \(ro.created!): \(ro.id!)")
                self.addMember(room:ro)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                return
            }
        }
    }
    
    // Add a support rep to the room
    func addMember(room:Room) {
        if let email = EmailAddress.fromString(supportRepEmail){
            spark!.memberships.create(roomId: room.id!, personEmail: email) { response in
                switch response.result {
                case .success(let membership):
                    print("A member \(self.supportRepEmail) has been added into the room. ID:\(membership)")
                    self.sendMessage(room:room)
                case .failure(let error):
                    print("Adding a member to the room has been failed: \(error.localizedDescription)")
                    return
                }
            }
        }
    }
    
    // Post a text message to the room
    func sendMessage(room:Room) {
        spark!.messages.post(roomId: room.id!, text: "Hello, anyone can help me?") { response in
            switch response.result {
            case .success(let message):
                print("Message: \"\(message)\" has been sent to the room!")
                self.roomSuccessLabel.text = "The Spark room and rep are ready!"
            case .failure(let error):
                print("Got error when posting a message: \(error.localizedDescription)")
            }
        }
    }
    
    // Sign in and do the authorization via Oauth
    @IBAction func signInAndAuthorize(_ sender: Any) {
        signInPrompt.text = "Logging in, please wait for a while!"
        authenticator!.authorize(parentViewController: self) { success in
            if success {
                self.spark!.authenticator.accessToken(){ token in
                    print("token :\(token!))")
                    self.afterLoginAndAuth()
                }
            }
        }
    }
    
    //Sign out
    @IBAction func signOut(_ sender: Any) {
        signInPrompt.text = "The app is not authorized to use the services. Please sign in first!"
        spark?.authenticator.deauthorize()
        beforeLoginAndAuth()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.roomName.delegate = self // set up textField delegate
        authenticator = OAuthAuthenticator.init(clientId: clientId, clientSecret: clientSecret, scope: scope, redirectUri: redirectUri)
        spark = Spark.init(authenticator: authenticator!)
        if  !authenticator!.authorized {
            beforeLoginAndAuth()
        } else {
            spark!.authenticator.accessToken(){ token in
                print("token :\(token!))")
            }
            afterLoginAndAuth()
        }
    }
    
    
    func beforeLoginAndAuth() {
        signInButton.isHidden = false
        signOutButton.isHidden = true
        line2.isHidden = true
        textSupportLabel.isHidden = true
        roomName.isHidden = true
        createRoomButton.isHidden = true
        roomSuccessLabel.isHidden = true
        line1.isHidden = true
        
        audioVideoSupportLabel.isHidden = true
        callSalesTeam.isHidden = true
        callSupportTeam.isHidden = true
        callBillingTeam.isHidden = true
        callStatusLabel.isHidden = true
        callerLabel.isHidden = true
        callerView.isHidden = true
        calledLabel.isHidden = true
        calledView.isHidden = true
        
        signInPrompt.isHidden = false
    }
    
    func afterLoginAndAuth() {
        
        line2.isHidden = false
        signInButton.isHidden = true
        signOutButton.isHidden = false
        textSupportLabel.isHidden = false
        roomName.isHidden = false
        createRoomButton.isHidden = false
        roomSuccessLabel.isHidden = false
        
        line1.isHidden = false
        
        audioVideoSupportLabel.isHidden = false
        callSalesTeam.isHidden = false
        callSupportTeam.isHidden = false
        callBillingTeam.isHidden = false
        callStatusLabel.isHidden = false
        callerLabel.isHidden = false
        callerView.isHidden = false
        calledLabel.isHidden = false
        calledView.isHidden = false
        
        signInPrompt.isHidden = true
    }
    
    
    @IBAction func callOut(_ sender: Any) {
        
        callSalesTeam.isEnabled = false
        callSupportTeam.isEnabled = false
        callBillingTeam.isEnabled = false
        
        var dest:String = "adkong@cisco.com"
        let i:Int = (sender as AnyObject).tag!
        switch i {
        case 1:
            dest = "sales team number"
        case 2:
            dest = "support team number"
        case 3:
            dest = "billing team number"
        default:
            dest="default number"
        }
        
        // Register the device
        spark?.phone.register() { error in
            if error == nil {
                // Make a call
                var outboundCall:Call? = nil
                self.spark?.phone.dial(dest, option:MediaOption.audioVideo(local: self.callerView, remote: self.calledView)) { response in
                    switch response {
                    case .success(let call):
                        outboundCall = call
                        self.initCallCallBack(outboundCall!)
                        print("Call succeeded!")
                    case .failure(let error):
                        print("Call failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Failed to register!")
            }
        }
    }
    
    
    func initCallCallBack(_ call:Call){
        
        call.onRinging = {
            self.callStatusLabel.text = "Call is ringing"
            print("callDidBeginRinging")
        }
        
        call.onConnected = {
            self.callStatusLabel.text = "Call is connected"
            print("callDidConnect")
        }
        
        call.onDisconnected = { event in
            
            switch event {
            case .localCancel:
                self.callStatusLabel.text = "Local Cancel. Idle"
                print("Local Cancel!")
            case .localDecline:
                self.callStatusLabel.text = "Local Decline. Idle"
                print("Local Decline")
            case .localLeft:
                self.callStatusLabel.text = "Local Left. Idle"
                print("Local Left")
            case .otherConnected:
                self.callStatusLabel.text = "Other Connected. Idle"
                print("Other Connected")
            case .otherDeclined:
                self.callStatusLabel.text = "Other Declined. Idle"
                print("Other Declined")
            case .remoteCancel:
                self.callStatusLabel.text = "Remote Cancel. Idle"
                print("Remote Cancel")
            case .remoteDecline:
                self.callStatusLabel.text = "Remote Decline. Idle"
                print("Remote Decline")
            case .remoteLeft:
                self.callStatusLabel.text = "Remote Left. Idle"
                print("Remote Left")
            case .error(let error):
                print("\(error.localizedDescription)")
            }
            
            self.callSalesTeam.isEnabled = true
            self.callSupportTeam.isEnabled = true
            self.callBillingTeam.isEnabled = true
        }
            
        call.onMediaChanged = { event in
            switch event {
            case .cameraSwitched:
                self.callStatusLabel.text = "Camera Switched"
                print("Camera Switched")
            case .localVideoViewSize:
                self.callStatusLabel.text = "Local Video View Size"
                print("Local Video View Size")
            case .receivingAudio(true):
                self.callStatusLabel.text = "Receiving Audio"
                print("Receiving Audio")
            case .receivingVideo(true):
                self.callStatusLabel.text = "Receiving Video"
                print("Receiving Video")
            case .remoteSendingAudio(true):
                self.callStatusLabel.text = "Remote Sending Audio"
                print("Remote Sending Audio")
            case .remoteSendingVideo(true):
                self.callStatusLabel.text = "Remote Sending Video"
                print("Remote Sending Video")
            case .remoteVideoViewSize:
                self.callStatusLabel.text = "Remote Video View Size"
                print("Remote Video View Size")
            case .sendingAudio(true):
                self.callStatusLabel.text = "Sending Audio"
                print("Sending Audio")
            case .sendingVideo(true):
                self.callStatusLabel.text = "Sending Video"
                print("Sending Video")
            case .spearkerSwitched:
                self.callStatusLabel.text = "Speaker Switched"
                print("Speaker Switched")
            default:
                print("Media Changed - No Reason")
            }
        }
    }
    
    // resign keyboard when pressing an enter.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // after inputting enter, resign the keyboard.
        return true
    }
}
