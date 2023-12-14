
import UIKit
import OpenTok
import AVFoundation


var kApiKey = ""
var kSessionId = ""
var kToken = ""

/* Kindly go through https://neru-68eeb4cf-video-server-live.euw1.runtime.vonage.cloud/app.html ans set the below URL if required with your room. */
let credentialUrl = URL(string: "https://neru-68eeb4cf-video-server-live.euw1.runtime.vonage.cloud/session/47807831/rahul")!


let kWidgetHeight = 240
let kWidgetWidth = 320

class ViewController: UIViewController {
    
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var unmuteButton: UIButton!
    @IBOutlet weak var frontCameraButton: UIButton!
    @IBOutlet weak var backCameraButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disConnectButton: UIButton!
    
    
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    var subscriber: OTSubscriber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.drawButtonsGrid()
        self.getAPIDdata()
    }
    
    func getAPIDdata() {
        let task = URLSession.shared.dataTask(with: credentialUrl) {(data, response, error) in
            guard let data = data else { return }
            do {
                    var dictonary:NSDictionary?
                    do {
                        dictonary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                         
                        if (dictonary?["apiKey"] != nil) {
                            kApiKey = dictonary?["apiKey"]! as! String
                            kSessionId =  dictonary?["sessionId"]! as! String
                            kToken =  dictonary?["token"]! as! String
                        } else {
                            DispatchQueue.main.async {
                                        let alert = UIAlertController(title: "Alert", message: "Token not found.Please correct the URL and try.If problem persist please conatct the admin.", preferredStyle: UIAlertController.Style.alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                            }
                        }
                                } catch let error as NSError {
                                    print(error)
                                }
            }
        }
        task.resume()
    }
    
    func drawButtonsGrid(){

        let offset = 10 // set offset on X & Y axes
        
        let btnsOnX = 4 // how many buttons in row
        let btnSize = (Int(self.view.frame.width) - (offset * (btnsOnX + 5))) / btnsOnX //      
        var xRow = 0
        var xPosMultiplier = 0
        
        for i in 0..<8 {

            xPosMultiplier += 1
            
            if (i % btnsOnX == 0) { // change row each 4x
                xRow += 1
                xPosMultiplier = 0
                print("")
            }
           
            let xPos = offset + (xPosMultiplier * offset) + (xPosMultiplier * btnSize)
            let yPos = (offset + (xRow * offset) + (xRow * btnSize)) - (btnSize + offset)

            
 //           let btnTitle = String(format: "%02d", i) + String(format: "-%02d", i + 1)
            
            let btn = UIButton()
            btn.frame = CGRect(x: CGFloat(xPos + 20), y: CGFloat(yPos + Int(self.view.frame.height)/2 + Int(self.view.frame.height)/6), width: CGFloat(btnSize), height: CGFloat(btnSize)) // 20 - offset from top buttons
            btn.tag = i
            btn.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            btn.backgroundColor = UIColor.lightGray
            btn.setTitleColor(.black, for: .normal)
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor.lightGray.cgColor
            btn.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            btn.titleLabel?.textAlignment = .center
            if(btn.tag == 0) {
                btn.setTitle("Start Session", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.connectAction), for: .touchUpInside)
            } else if (btn.tag == 1) {
                btn.setTitle("Mute", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.muteAction), for: .touchUpInside)
            } else if (btn.tag == 2) {
                btn.setTitle("Front Camera", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.frontCameraAction), for: .touchUpInside)
            }else if (btn.tag == 3) {
                btn.setTitle("Pause Video", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.pauseVideoAction), for: .touchUpInside)
            }else if (btn.tag == 4) {
                btn.setTitle("Stop Session", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.diconnectAction), for: .touchUpInside)
            }else if (btn.tag == 5) {
                btn.setTitle("Unmute", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.unmuteAction), for: .touchUpInside)
            }
            else if (btn.tag == 6) {
                btn.setTitle("Back Camera", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.backCameraAction), for: .touchUpInside)
            }
            else if (btn.tag == 7) {
                btn.setTitle("UnPause Video", for: UIControl.State())
                btn.addTarget(self, action: #selector(self.unPauseVideoAction), for: .touchUpInside)
            }
            
            self.view.addSubview(btn)
            
           // print("spacing: \(spacing), multiplier: \(xPosMultiplier), xPos: \(xPos), yPos: \(yPos), btnSize: \(btnSize)")
            
            
            if (i % btnsOnX  == 0) { // change row each 4x
                xPosMultiplier = 0 // reset with new row after x was set
            }
        }
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        print(stream)
        subscriber = OTSubscriber(stream: stream, delegate: self)
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
    @objc func connectAction(_ sender: UIButton){
        self.startAnimation(sender)
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        doConnect()
        } else {
            let alert = UIAlertController(title: "Alert", message: "Session,Token and API key can't be blank.Please restart application.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc func diconnectAction(_ sender: UIButton){
            if kApiKey != "" &&  kApiKey != "" && kToken != "" {
            self.startAnimation(sender)
            var error: OTError?
                session.disconnect(&error)
            } else {
                let alert = UIAlertController(title: "Alert", message: "Session,Token and API key can't be blank.Please restart application.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
    }

    @objc func muteAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
            publisher.publishAudio = false;
        }
    }
    
    @objc func unmuteAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
        publisher.publishAudio = true;
        }
    }
    
    @objc func frontCameraAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
        publisher.cameraPosition = .front
        }
    }
    
    @objc func backCameraAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
        publisher.cameraPosition = .back
        }
    }
    
    @objc func pauseVideoAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
        publisher.publishVideo = false
        }
    }
    
    @objc func unPauseVideoAction(_ sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        self.startAnimation(sender)
        publisher.publishVideo = true
        }
    }
    
    @IBAction func stopPublishAction(sender: UIButton){
        if kApiKey != "" &&  kApiKey != "" && kToken != "" {
        if(publisher.publishVideo ==  true) {
            publisher.publishVideo =  false
        } else {
            publisher.publishVideo =  true
        }
        }
    }
    
    func startAnimation(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.5,
                                   delay: 0,
                                   usingSpringWithDamping: CGFloat(0.20),
                                   initialSpringVelocity: CGFloat(6.0),
                                   options: UIView.AnimationOptions.allowUserInteraction,
                                   animations: {
                                    sender.transform = CGAffineTransform.identity
            },
                                   completion: { Void in()  }
        )
    }
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Stream Width" , stream.videoDimensions.width);
        print("Stream height" , stream.videoDimensions.height)
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")

    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
