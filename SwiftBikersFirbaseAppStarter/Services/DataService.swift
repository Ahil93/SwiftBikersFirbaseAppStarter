//
//  DataService.swift
//  SwiftBikersFirbaseAppStarter
//
//  Created by MacBook on 1/29/19.
//  Copyright © 2019 Ahil. All rights reserved.
//

import Foundation
import Firebase

//Gets a FIRDatabaseReference for the root of your Firebase Database.
let DB_BASE = Database.database().reference()

class DataService{
    
    static let instance = DataService()
    
    private var _REF_BASE = DB_BASE
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_GROUPS = DB_BASE.child("groups")
    private var _REF_FEED = DB_BASE.child("feed")
    
    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    var REF_GROUPS: DatabaseReference {
        return _REF_GROUPS
    }
    
    var REF_FEED: DatabaseReference {
        return _REF_FEED
    }
    
    func createDBUser(uid: String, userData: Dictionary<String, Any>) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
    
    func getUserName(forUID uid: String, handler: @escaping (_ userName : String) -> ()){
        REF_USERS.observeSingleEvent(of: .value) { (UserSnapshot) in
            guard let userSnap = UserSnapshot.children.allObjects as? [DataSnapshot] else{return}
            
            for user in userSnap{
                if(user.key ==  uid){
                    handler(user.childSnapshot(forPath: "email").value as! String)
                }
            }
        }
    }
    func uploadPost(withPostMsg message: String, forUID uid: String, withGroupKey groupKey:String?, postComplete : @escaping(_ status: Bool) -> ()){
        if(groupKey != nil){
            //Post in Group
            REF_GROUPS.child(groupKey!).child("messages").childByAutoId().updateChildValues(["content": message, "senderId": uid])
            postComplete(true)
            
        }
        else{
            //POST PUBLIC
            //childByAutoId generates a new child location using a unique key and returns a FIRDatabaseReference to it
            _REF_FEED.childByAutoId().updateChildValues(["content": message, "senderId": uid])
            postComplete(true)
        }
    }
    
    func getAllPosts(handler: @escaping(_ posts: [Post]) -> ()){
        var postArray = [Post]()
        REF_FEED.observeSingleEvent(of: .value) { (postMessageSnapshot) in
            
            guard let postMessageSnap = postMessageSnapshot.children.allObjects as? [DataSnapshot] else{return}
            
            for singlePost in postMessageSnap{
                let contentMsg = singlePost.childSnapshot(forPath: "content").value as! String
                let senderId = singlePost.childSnapshot(forPath: "senderId").value as! String
                let post = Post(content: contentMsg, senderId: senderId)
                postArray.append(post)
            }
            handler(postArray)
        }
        
    }
    
    func getEmail(forSearchQuery query: String, handler: @escaping (_ emailArray: [String]) -> ()) {
        var emailArray = [String]()
        REF_USERS.observe(.value) { (userSnapshot) in
            guard let userSnapshot = userSnapshot.children.allObjects as? [DataSnapshot] else { return }
            for user in userSnapshot {
                let email = user.childSnapshot(forPath: "email").value as! String
                
                if email.contains(query) == true && email != Auth.auth().currentUser?.email {
                    emailArray.append(email)
                }
            }
            handler(emailArray)
        }
    }
    
    func getIds(forUserNames userNames: [String], handler: @escaping(_ uidArray: [String]) -> ()){
        REF_USERS.observeSingleEvent(of: .value) { (UserSnapshot) in
            var idArray = [String]()
            guard let userSnap = UserSnapshot.children.allObjects as? [DataSnapshot] else{return}
            for user in userSnap{
                let email = user.childSnapshot(forPath: "email").value as! String
                if(userNames.contains(email)){
                    idArray.append(user.key)
                }
            }
            handler(idArray)
            
        }
    }
    
    func createGroup(withTitle title: String, andDescription description: String, forUserIds ids: [String], handler: @escaping (_ groupCreated: Bool) -> ()) {
        REF_GROUPS.childByAutoId().updateChildValues(["title": title, "description": description, "members": ids])
        handler(true)
    }
    
    func getAllGroups(handler : @escaping (_ groupsArray: [Group]) -> ()){
        var groupsArray = [Group]()
        REF_GROUPS.observeSingleEvent(of: .value) { (groupSnapshot) in
            guard let groupSnap = groupSnapshot.children.allObjects as? [DataSnapshot] else{return}
            
            for group in groupSnap{
                let memberArray = group.childSnapshot(forPath: "members").value as! [String]
                
                if(memberArray.contains((Auth.auth().currentUser?.uid)!)){
                    let title = group.childSnapshot(forPath: "title").value as! String
                    let des = group.childSnapshot(forPath: "description").value as! String
                    let group = Group(title: title, description: des, key: group.key, members: memberArray, memberCount: memberArray.count)
                    groupsArray.append(group)
                }
            }
            handler(groupsArray)
        }
    }
    
    func getEmailsFor(group: Group, handler: @escaping (_ emailArray: [String]) -> ()) {
        var emailArray = [String]()
        REF_USERS.observeSingleEvent(of: .value) { (userSnapshot) in
            guard let userSnapshot = userSnapshot.children.allObjects as? [DataSnapshot] else { return }
            for user in userSnapshot {
                if group.members.contains(user.key) {
                    let email = user.childSnapshot(forPath: "email").value as! String
                    emailArray.append(email)
                }
            }
            handler(emailArray)
        }
    }
    
    func getAllMessagesFor(desiredGroup: Group, handler: @escaping (_ messagesArray: [Post]) -> ()) {
        var groupMessageArray = [Post]()
        REF_GROUPS.child(desiredGroup.key).child("messages").observeSingleEvent(of: .value) { (groupMessageSnapshot) in
            guard let groupMessageSnapshot = groupMessageSnapshot.children.allObjects as? [DataSnapshot] else { return }
            for groupMessage in groupMessageSnapshot {
                let content = groupMessage.childSnapshot(forPath: "content").value as! String
                let senderId = groupMessage.childSnapshot(forPath: "senderId").value as! String
                let groupMessage = Post(content: content, senderId: senderId)
                groupMessageArray.append(groupMessage)
            }
            handler(groupMessageArray)
        }
    }
    
}

