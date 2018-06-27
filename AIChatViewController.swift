//
//  AIChatViewController.swift
//  InnaAI
//
//  Created by Md. Sarowar Jahan Faruk on 2/4/18.
//  Copyright © 2018 Md. Sarowar Jahan Faruk. All rights reserved.
//
import ApiAI
import UIKit
import JSQMessagesViewController
import Speech

enum ChatWindowStatus{
    case minimised
    case maximised
}

class AIChatViewController: JSQMessagesViewController, UINavigationControllerDelegate {
    
    var messagesController: MessagesController?

    
    var messages = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    lazy var speechSynthesizer = AVSpeechSynthesizer()
    lazy var botImageView = UIImageView()
    
    var chatWindowStatus : ChatWindowStatus = .maximised
    var botImageTapGesture: UITapGestureRecognizer?
    
    //MARK: Life Cycle Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        self.navigationItem.title = "INNA BOT";

        
        self.senderId = "some userId"
        self.senderDisplayName = "some userName"
        
        SpeechManager.shared.delegate = self
        
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(gesture:)))
        self.view.addGestureRecognizer(swipeGesture)
        self.addMicButton()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        let deadlineTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            self.populateWithWelcomeMessage()
        })
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleCancel(){
        let innaChat = MessagesController()
        innaChat.backToAiController = self
        let navController = UINavigationController(rootViewController: innaChat)
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: Using Methods in View
    func addMicButton(){
        let height = self.inputToolbar.contentView.leftBarButtonContainerView.frame.size.height
        let micButton = UIButton(type: .custom)
        micButton.setImage(#imageLiteral(resourceName: "microphone"), for: .normal)
        micButton.frame = CGRect(x: 0, y: 0, width: 25, height: height)
        self.inputToolbar.contentView.leftBarButtonItemWidth = 25
        self.inputToolbar.contentView.leftBarButtonContainerView.addSubview(micButton)
        self.inputToolbar.contentView.leftBarButtonItem.isHidden = true
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOfMic(gesture:)))
        micButton.addGestureRecognizer(longPressGesture)
    }

    // for initial messages
    func populateWithWelcomeMessage(){
        self.addMessage(withId: "BotId", name: "Bot", text: "Hi I am INNA")
        self.finishReceivingMessage()
        self.addMessage(withId: "BotId", name: "Bot", text: "I am here to share information about Sylhet foodies")
        self.finishReceivingMessage()
    }
    // add message  text
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    func minimisedbot(){
        if chatWindowStatus == .maximised{
            self.inputToolbar.contentView.textView.resignFirstResponder()
            UIView.animate(withDuration: 0.5, animations: {
                let rect = CGRect(x: 300, y: 50, width: 80, height: 80)
                self.view.frame = rect
                self.view.clipsToBounds = true
                self.view.layer.cornerRadius = 40
            }, completion: {(completed) in
                self.inputToolbar.isUserInteractionEnabled = false
                self.botImageView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
                self.botImageView.image = #imageLiteral(resourceName: "BotImage")
                self.botImageView.clipsToBounds = true
                self.botImageView.layer.cornerRadius = 40
                self.view.addSubview(self.botImageView)
                self.chatWindowStatus = .minimised
                self.botImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gesture:)))
                self.view.addGestureRecognizer(self.botImageTapGesture!)
            })
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .default
    }
    
    // MARK: Gesture Methods
    @objc func handleLongPressOfMic(gesture:UILongPressGestureRecognizer){
        
        if gesture.state == .began{
            SpeechManager.shared.startRecording()
        }
            
        else if gesture.state == .ended{
            SpeechManager.shared.stopRecording()
            
            if inputToolbar.contentView.textView.text == "Say something..."{
                inputToolbar.contentView.textView.text = ""
            }
        }
    }
    
    //  handle swipe when chatwindowstatus maximised to minimised
    @objc func handleSwipe(gesture:UISwipeGestureRecognizer){
        minimisedbot()
    }
    
    // handle Tap  when chatwindowstatus minimised to maximised
    @objc func handleTap(gesture: UITapGestureRecognizer){
        
        if  chatWindowStatus == .minimised {
            
            botImageView.removeFromSuperview()
            UIView.animate(withDuration: 0.5, animations: {
                let rect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                self.view.frame = rect
                self.view.clipsToBounds = true
                self.view.layer.cornerRadius = 0
                self.chatWindowStatus = .maximised
            }, completion: {(completed) in
                self.inputToolbar.isUserInteractionEnabled = true
                self.view.removeGestureRecognizer(self.botImageTapGesture!)
            })
        }
    }
    
  
    // MARK: Api.ai use
    
    func performQuery(senderId: String,name: String , text: String){
        let request = ApiAI.shared().textRequest()
        if text != ""{
            request?.query = text
        }
        else{
            return
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if response.result.action == "bot.quit" {
                if let parameters = response.result.parameters as? [String: AIResponseParameter] {
                    if let quit = parameters["quit"]?.stringValue {
                        let deadlineTime = DispatchTime.now() + .seconds(2)
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                            self.minimisedbot()
                        })
                    }
                }
            }
            if let textResponse = response.result.fulfillment.speech {
                SpeechManager.shared.speak(text: textResponse)
                self.addMessage(withId: "BotId", name: "Bot", text: textResponse)
                self.finishReceivingMessage()
            }
            
        }, failure: {(request, error) in
           // print(error)
        })
        
        ApiAI.shared().enqueue(request)
    }
  
    
    
    
    
    // MARK: JSQMessagesViewController related method
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId{
            return outgoingBubbleImageView
        }
        else{
            return incomingBubbleImageView
        }
    }
    
    // don't use avatars  (JSQMessageAvatarImageDataSource)
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // set up cell text color
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView.textColor = UIColor.black
        }
        else{
            cell.textView.textColor = UIColor.white
        }
        return cell
    }
    
    // send button use for message send
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        addMessage(withId: senderId, name: senderDisplayName!, text: text!)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        performQuery(senderId: senderId, name: senderDisplayName, text: text!)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        performQuery(senderId: senderId, name: senderDisplayName, text: "Multimedia")
    }
}

// protocol func implementation in AIChatViewController class used in extension keyword
extension AIChatViewController: SpeechManagerDelegate{
        
        func didStartedListening(status:Bool){
            if status{
                self.inputToolbar.contentView.textView.text = "Say something..."
            }
        }
    
        func didReceiveText(text:String){
            self.inputToolbar.contentView.textView.text = text
            
            if text != "Say something..."{
                self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
            }
            
        }
    }

