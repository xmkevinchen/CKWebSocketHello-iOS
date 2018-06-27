//
//  ViewController.swift
//  CKWebSocketHello-iOS
//
//  Created by Kevin Chen on 6/25/18.
//  Copyright © 2018 Kai Chen. All rights reserved.
//

import UIKit
import StompClientLib

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var inputTextField: UITextField!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet var inputContentView: UIView!
    var leftBarItem: UIBarButtonItem!
    var rightBarItem: UIBarButtonItem!
    var greetings: [Greeting] = []
    
    var isConnected: Bool = false {
        didSet {
            if let leftBarItem = leftBarItem, let rightBarItem = rightBarItem {
                leftBarItem.isEnabled = !isConnected
                rightBarItem.isEnabled = isConnected
            }
        }
    }
    
    let socket = StompClientLib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        inputContentView.translatesAutoresizingMaskIntoConstraints = false;
        
        toolbar.addSubview(inputContentView)
        toolbar.pinSubview(inputContentView)
        
        leftBarItem = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(connect(_:)))
        rightBarItem = UIBarButtonItem(title: "Disconnect", style: .plain, target: self, action: #selector(disconnect(_:)))
        
        navigationItem.leftBarButtonItem = leftBarItem
        navigationItem.rightBarButtonItem = rightBarItem
        
        isConnected = false
        
    }
    
    deinit {
        socket.disconnect()
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        
        if let message = inputTextField.text, !message.isEmpty, socket.connection {
            let hello = HelloMessage(name: message)
            if let jsonData = try? JSONEncoder().encode(hello), let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                socket.sendJSONForDict(dict: jsonObject as AnyObject, toDestination: "/app/hello")
            }
        }
        
        inputTextField.text = nil
        inputTextField.resignFirstResponder()
    }
    
    @objc func connect(_ sender: Any) {
        if let url = URL(string: "http://localhost:8080/greeting/websocket") {
            let request = URLRequest(url: url)
            socket.openSocketWithURLRequest(request: request as NSURLRequest, delegate: self)
        }
        
    }
    
    @objc func disconnect(_ sender: Any) {
        socket.disconnect()
    }
    
}

extension ViewController: StompClientLibDelegate {
    func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, withHeader header: [String : String]?, withDestination destination: String) {
        
    }
    
    func stompClientJSONBody(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
        if let jsonBody = jsonBody, let jsonData = jsonBody.data(using: .utf8), let greeting = try? JSONDecoder().decode(Greeting.self, from: jsonData) {
            print("====> jsonString: \(jsonBody)")
            let indexPath = IndexPath(row: greetings.count, section: 0)
            greetings.append(greeting)
            tableView.beginUpdates()
            tableView.insertRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func stompClientDidDisconnect(client: StompClientLib!) {
        isConnected = false
        greetings.removeAll();
        tableView.reloadData()
    }
    
    func stompClientDidConnect(client: StompClientLib!) {
        isConnected = true
        client.subscribe(destination: "/topic/greetings")
    }
    
    func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
        
    }
    
    func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
        
    }
    
    func serverDidSendPing() {
        
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return greetings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let greeting = greetings[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GreetingCell", for: indexPath)
        
        cell.textLabel?.text = greeting.content
        
        return cell
    }
}

struct HelloMessage: Encodable {
    let name: String
}

struct Greeting: Decodable {
    let content: String
}

public extension UIView {
    
    public func pinSubview(_ subview: UIView, to attribute: NSLayoutAttribute) {
        
        addConstraint(NSLayoutConstraint(item: self,
                                         attribute: attribute,
                                         relatedBy: .equal,
                                         toItem: subview,
                                         attribute: attribute,
                                         multiplier: 1.0,
                                         constant: 0))
        
    }
    
    public func pinSubview(_ subview: UIView, to attributes: [NSLayoutAttribute] = [.top, .bottom, .leading, .trailing]) {
        attributes.forEach { pinSubview(subview, to: $0) }
    }
    
}
