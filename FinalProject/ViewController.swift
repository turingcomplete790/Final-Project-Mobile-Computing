//
//  ViewController.swift
//  FinalProject
//
//  Created by Faisal(Zack) Ashour on 11/25/22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var audioSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    @IBOutlet weak var statusInfo: UILabel!
    @IBOutlet weak var PlayButton: UIButton!
    @IBOutlet weak var TimeStamp: UILabel!
    @IBOutlet weak var StopButton: UIButton!
    @IBOutlet weak var RecordButton: UIButton!
    let paths = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)
    override func viewDidLoad() {
        super.viewDidLoad()
        audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission(){[unowned self] allowed in DispatchQueue.main.async {
                if allowed{
                    self.setupUI()
                }
                else {
                    self.statusInfo.text = "Could not start session"
                }
            }}
            // Do any additional setup after loading the view.
        }catch{
            statusInfo.text = "Could not record permission error"
        }
    }
    func setupUI(){
        RecordButton.addTarget(self, action: #selector(recordPressed), for: .touchUpInside)
    }
    @objc func recordPressed(){
        statusInfo.text = "Recording has started"
        if audioRecorder == nil {
            recordingStarted()
        }
        else {
            recordingStopped(success: true)
        }
    }
    
    func recordingStarted(){
        let current_directory = paths[0]
        let fileName = current_directory.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url:fileName,settings:settings)
        }catch{
            recordingStopped(success: false)
        }
    }
    func recordingStopped(success: Bool){
        audioRecorder.stop()
        audioRecorder = nil
        if success{
            statusInfo.text = "Not Currently Recording"
        }
        else {
            statusInfo.text = "Recording Failed"
        }
    }
}

