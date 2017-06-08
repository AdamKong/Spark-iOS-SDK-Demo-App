
# Integrate audio and video features into an iOS app via Spark iOS SDK


Let’s say, you want to develop an app on the iOS platform that allows you and your customers to easily communicate with each other. You want to show your products, but also want to provide live support to them when they need help. Would it be amazing if your app can build audio and video in the app and make the connections with one sliding touch and one pressing!

Now, this becomes possible and much simpler - Cisco has released an iOS Spark SDK (Android version is coming), which allows any iOS developer to easily integrate Spark audio and video calling features into your iOS app.

We write a sample app here. There is no complex script to learn and Cisco takes care of all underlying audio and media flows, so it’s very quick to learn and implement. We’re going to show you a demo, which explains how the SDK exactly works, so you can expand and modify it into any of your own app user case and ideas.

The demo is a “VIP Help Centre” where a user can get not only chat support but also audio and video assistance. Please see the below video:

In the demo video, the caller view is blank, that’s because I was testing on an iPhone simulator which does not has a camera. On a real iPhone, it will show the caller’s video. If you have installed Xcode and it’s open, the built-in simulator can be found by “Xcode  Open Developer Tool  Simulator” in the menu. The demo app works well with the simulators of iPhone 6 and 7 series.

Ok, time to get started. 

## Preparation work:

At the first step, we have to get the SDK installed, which is outlined here at https://developer.ciscospark.com/sdk-for-ios.html, so I won’t talk much about this step. Once the SparkSDK is imported into the app without any error/alert prompted, we are ready for the next step.

Secondly, we need to create an OAuth app. It’s used for the iOS app to get an access token so that it can operate on behalf of a user (security and authentication). Here is the document for how Spark OAuth works - https://developer.ciscospark.com/authentication.html, and this is the place to create an OAuth app - https://developer.ciscospark.com/add-integration.html. The redirecturi has to be “Sparkdemoapp://response”, the scope has to be “spark:all”. Then we get the clientId and clientSecret.

Lastly, we need a simple UI. Since this is just a demo, I won’t do much decoration work, and just show the main UI elements.

## Sign in, Authorize and Sign out: 

After the app loads, we need to see whether the user has already authorized his app or not. The below two lines are to get an initialized authenticator, then get a Spark object:

```swift
authenticator = OAuthAuthenticator.init(clientId: clientId, clientSecret: clientSecret, scope: scope, redirectUri: redirectUri)
        
spark = Spark.init(authenticator: authenticator!)
```

We can use the “authorized” attribute of “authenticator” to see if the user has authorized or not. If no, go to the beforeLoginAndAuth() function to ask the user to log in and authorize, otherwise, let him pass the step and go to  afterLoginAndAuth(). The whole script would be:

```swift
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

```

On the “Sign in and Authorize” button, we register a “Touch Up Inside” event:





 And under it we do the login and authorization work:

```swift
// sign in and do the authorization via Oauth
authenticator!.authorize(parentViewController: self) { success in
            if success {
                self.spark!.authenticator.accessToken(){ token in
                    print("token :\(token!))")
                    self.afterLoginAndAuth()
                }
            }
        }
```

The authorize() method starts the signing in and OAuth process. It redirects the user to Spark interface to let him input username and password and accept the requested permissions defined in the OAuth scope. If it succeeds, the access token will be stored in environmental variables so that other actions can use it. Here we print out the token string for logging, then redirect to the afterLoginAndAuth(). In the view, we also have a “sign out” button which allows a user to de-authorize to sign out:

```swift
//sign out
spark?.authenticator.deauthorize()
```

## Chat Support Channel:

Now, we’re in the main board. The “Chat Support” channel allows a user to create a Spark space with a custom space name. On the “Create a space” button, we register a “Touch Up Inside” event:





And under it we create a space:

```swift
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
```

And add a support rep into the space by email:

```swift
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
```

Post a message to the space:

```swift
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
```

The complete sample script is:

```swift
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
```

All the actions use the access token we get in authorization step at the backend. If you want to know how exactly a space is created, how a message is posted, etc., please refer to this document for the detailed information - https://developer.ciscospark.com/getting-started.html. They’re basically HTTP requests, and the doc shows how to set the method, header and body.


## Audio and Video Channel:

In the “Audio & Video Support” channel, we can send audio and video calls. Note, it can dial to not only a Spark address, but also any valid sip and PSTN destinations as long as you have enough privileges. In the “call” buttons, we register a “Touch Up Inside” event:





And under that we start doing the actual call.

The first step is to register a device:

```swift
spark?.phone.register()
```

If it succeeds, do the actual call:

```swift
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
```

Note the “MediaOption.audioVideo”, it allows “audio” or “video” or both, and we can choose it based on requirement. It requires two parameters which specify the local and remote media views. In my demo, they’re the “callerView” and “calledView” views, defined as below:

```swift
@IBOutlet weak var callerView: MediaRenderView!
@IBOutlet weak var calledView: MediaRenderView!
```


Monitor call status:

In the call method, you may notice the initCallCallBack() method, and it defines the callback functions, as below:

```swift
call.onRinging
call.onConnected
call.onDisconnected
call.onMediaChanged
call.onCapabilitiesChanged
```

We can implement them and reflect the status to the UI. For example, in this demo I implement the .onRinging method:

```swift
call.onRinging = {
            self.callStatusLabel.text = "Call is ringing"
            print("callDidBeginRinging")
        }
```

and reflect the status to the callStatusLabel label then users can see “Call is ringing” when it rings on the called side.


So the whole script is like:

```swift
func initCallCallBack(_ call:Call){
        
        call.onRinging = {
            self.callStatusLabel.text = "Call is ringing"
            print("callDidBeginRinging")
        }
        
        call.onConnected = {
            self.callStatusLabel.text = "Called is connected"
            print("callDidConnect")
        }
        
        call.onDisconnected = { event in
            
            switch event {
            case .localCancel:
                self.callStatusLabel.text = "Local Cancel"
                print("Local Cancel!")
            case .localDecline:
                self.callStatusLabel.text = "Local Decline"
                print("Local Decline")
                .
                .
                .
            default:
                print("Disconnected - No Reason")
            }
        }        
        
        call.onMediaChanged = { event in
            switch event {
            case .cameraSwitched:
                self.callStatusLabel.text = "Camera Switched"
                print("Camera Switched")
            case .localVideoViewSize:
                self.callStatusLabel.text = "Local Video View Size"
                print("Local Video View Size")
            .
            .
            .

            default:
                print("Media Changed - No Reason")
            }
        }
        }
```

Now, we have finished the coding work, and the complete code can be found on Github - https://github.com/AdamKong/Spark-iOS-SDK-Demo-App

If you have any questions, please contact devsupport@ciscospark.com 24/7/365 - we’re happy to help all the time!

