//
//  ChatViewController.swift
//  NexSeedChat
//
//  Created by yonekan on 2019/08/15.
//  Copyright © 2019 yonekan. All rights reserved.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {

    // 全メッセージを保持する変数
    var messages: [Message] = [] {
        // 変数の中身が書き換わった時
        didSet {
            // 画面を更新する
            messagesCollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        
        // Firestoreへ接続
        let db = Firestore.firestore()
        
        // messagesコレクションを監視する
        db.collection("messages").order(by: "sentDate").addSnapshotListener { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                return
            }
            
            var messages: [Message] = []
            
            for document in documents {
                
                let uid = document.get("uid") as! String
                let name = document.get("name") as! String
                let photoUrl = document.get("photoUrl") as! String
                let text = document.get("text") as! String
                let sentDate = document.get("sentDate") as! Timestamp
                
                // 該当するメッセージの送信者の作成
                let chatUser =
                    ChatUser(uid: uid, name: name, photoUrl: photoUrl)
                
                let message =
                        Message(user: chatUser,
                                text: text,
                                messageId: document.documentID,
                                sentDate: sentDate.dateValue())
                
                messages.append(message)
                
            }
            
            self.messages = messages
        }
        
    }
    
}

extension ChatViewController: MessagesDataSource {
    
    // 送信者（ログインユーザー）
    func currentSender() -> SenderType {
        // 現在ログインしている人を取得
        let user = Auth.auth().currentUser!
        
        // ログイン中のユーザーのUID、displayNameを使って、
        // MessageKit用に送信者の情報を作成
        return Sender(id: user.uid, displayName: user.displayName!)
        
    }
    
    // 画面に表示するメッセージ
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
        
    }
    
    // 画面に表示するメッセージの件数
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

extension ChatViewController: MessagesLayoutDelegate {
    
}

extension ChatViewController: MessagesDisplayDelegate {
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner!
        
        if isFromCurrentSender(message: message) {
            // メッセージの送信者が自分の場合
            corner = .bottomRight
        } else {
            // メッセージの送信者が自分以外の場合
            corner = .bottomLeft
        }
        
        return .bubbleTail(corner, .curved)
        
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        if isFromCurrentSender(message: message) {
            return UIColor(red: 100/255, green: 63/255, blue: 222/255, alpha: 1)
        } else {
            return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        // 全メッセージのうち対象の1つを取得
        let message = messages[indexPath.section]
        
        // 取得したメッセージの送信者を取得
        let user = message.user
        
        let url = URL(string: user.photoUrl)
        
        do {
            // urlを元に画像のデータを取得
            let data = try Data(contentsOf: url!)
            // 取得したデータを元に、ImageViewを作成
            let image = UIImage(data: data)
            // ImageViewと名前を元にアバターアイコン作成
            let avatar = Avatar(image: image, initials: user.name)
            
            // アバターアイコンを画面に設置
            avatarView.set(avatar: avatar)
            return
        } catch let err {
            print(err.localizedDescription)
        }
        
    }
}

extension ChatViewController: MessageCellDelegate {
    
}

// 送信バーに関する設定
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        // ログインユーザーの取得
        let user = Auth.auth().currentUser!
        
        // Firestoreに接続
        let db = Firestore.firestore()
        
        // Firestoreにメッセージや送信者の情報を登録
        db.collection("messages").addDocument(data: [
            "uid": user.uid,
            "name": user.displayName as Any,
            "photoUrl": user.photoURL?.absoluteString as Any,
            "text": text,
            "sentDate": Date()
        ])
        
        // メッセージの入力欄を空にする
        inputBar.inputTextView.text = ""
    }
    
}
