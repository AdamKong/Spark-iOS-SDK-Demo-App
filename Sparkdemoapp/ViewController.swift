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
    
    var spark : Spark?
    var authenticator:OAuthAuthenticator?
    
    let supportRepEmail = ""
    let salesTeamNumber = ""
    let supportTeamNumber = ""
    let billingTeamNumber = ""
    let defaultNumber = ""
    
    let clientId = ""
    let clientSecret = ""
    let scope = "spark:all"
    let redirectUri = "Sparkdemoapp://response"
    
    //outlets
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var signInPrompt: UILabel!
    
    @IBOutlet weak var line2: UILabel!
    @IBOutlet weak var textSupportLabel: UILabel!
    @IBOutlet weak var spaceName: UITextField!
    @IBOutlet weak var createSpaceButton: UIButton!
    @IBOutlet weak var spaceSuccessLabel: UILabel!
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
    
    
    //actions
    
    //create a space when a user clicks the "create a space" button
    @IBAction func createSpace(_ sender: Any) {
        
        spaceName.isHidden = true
        createSpaceButton.isHidden = true
        spaceSuccessLabel.isHidden = false
        spaceSuccessLabel.text = "Creating a space, please wait!"
        
        var spaceTitle:String
        if spaceName.text == nil {
            spaceTitle = "Help Space"
        } else {
            spaceTitle = spaceName.text!
            if spaceTitle.trimmingCharacters(in: .whitespaces) == "" {
                spaceTitle = "Help Space"
            }
        }
        print("space title is: \(spaceTitle)")
        
        // Create a new space
        spark!.rooms.create(title: spaceTitle){ response in
            switch response.result {
            case .success(let space):
                print("\(space.title!), created \(space.created!): \(space.id!)")
                self.addMember(space:space)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                self.spaceSuccessLabel.text = "Failed to create a space, pls retry later!"
                return
            }
        }
    }
    
    // Add a support rep to the space
    func addMember(space:Room) {
        if let email = EmailAddress.fromString(supportRepEmail){
            spark!.memberships.create(roomId: space.id!, personEmail: email) { response in
                switch response.result {
                case .success(let membership):
                    print("A member \(self.supportRepEmail) has been added into the space. membershipID:\(membership)")
                    self.sendMessage(space:space)
                case .failure(let error):
                    print("Adding a member to the space has been failed: \(error.localizedDescription)")
                    self.spaceSuccessLabel.text = "Failed to add a rep, pls retry later!"
                    return
                }
            }
        }
    }
    
    // Post a text message to the space
    func sendMessage(space:Room) {
        spark!.messages.post(roomId: space.id!, text: "Hello, anyone can help me?") { response in
            switch response.result {
            case .success(let message):
                print("Message: \"\(message)\" has been sent to the space!")
                self.spaceSuccessLabel.text = "The Spark space and rep are ready!"
            case .failure(let error):
                print("Got error when posting a message: \(error.localizedDescription)")
                self.spaceSuccessLabel.text = "Failed to post a message, pls retry later!"
                return
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
        self.spaceName.delegate = self // set up textField delegate
        
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
        spaceName.isHidden = true
        createSpaceButton.isHidden = true
        spaceSuccessLabel.isHidden = true
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
        spaceName.isHidden = false
        spaceName.text = ""
        createSpaceButton.isHidden = false
        spaceSuccessLabel.isHidden = true
        
        line1.isHidden = false
        
        audioVideoSupportLabel.isHidden = false
        callSalesTeam.isHidden = false
        callSupportTeam.isHidden = false
        callBillingTeam.isHidden = false
        callStatusLabel.isHidden = false
        callStatusLabel.text = "Idle"
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
        
        var dest:String = defaultNumber
        let i:Int = (sender as AnyObject).tag!
        switch i {
        case 1:
            dest = salesTeamNumber
        case 2:
            dest = supportTeamNumber
        case 3:
            dest = billingTeamNumber
        default:
            dest = defaultNumber
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
                self.callStatusLabel.text = "Local Video View Size Changed"
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
                self.callStatusLabel.text = "Remote Video View Size Changed"
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
