//
//  ViewController.swift
//  FinalProject
//
//  Created by Faisal(Zack) Ashour on 11/25/22.
//

import UIKit
import AVKit
import SoundAnalysis
import Foundation

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.instrumentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell =  UITableViewCell(style: .default, reuseIdentifier: nil)
              cell.textLabel?.text = instrumentArray[indexPath.row]
              return cell
    }
    
    private func convert(id: String) -> String {
        let mapping = ["cel" : "drum", "cla" : "clarinet", "flu" : "flute",
                       "gac" : "acoustic guitar", "gel" : "electric guitar",
                       "org" : "organ", "pia" : "piano", "sax" : "saxophone",
                       "tru" : "trumpet", "vio" : "violin", "voi" : "human voice"]
        return mapping[id] ?? id
    }
    //declare blank timer variable
    var timer = Timer()
    //let CellIdentifier = "com.zackashour.FinalProject"
    var instumentSet = Set<String>()
    var instrumentArray = [String]()
    @IBOutlet weak var instrumentTable: UITableView!
    @IBOutlet weak var statusInfo: UILabel!
    @IBOutlet weak var PlayButton: UIButton!
    @IBOutlet weak var TimeStamp: UILabel!
    @IBOutlet weak var StopButton: UIButton!
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = InstrumentClassifier()
    var streamAnalyzer: SNAudioStreamAnalyzer!
    let queue = DispatchQueue(label: "com.zackashour.FinalProject")

    override func viewDidLoad() {
        super.viewDidLoad()
        instrumentTable.dataSource = self
    }
    
    private func prepareForRecording() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [unowned self] (buffer, when) in
            self.queue.async {
                self.streamAnalyzer.analyze(buffer,
                                            atAudioFramePosition: when.sampleTime)
            }
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            statusInfo.text = "Error in starting Audio Engine"
        }
    }
    
    private func createClassificationRequest() {
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try streamAnalyzer.add(request, withObserver: self)
        } catch {
            statusInfo.text = "Failed to start classifer"
        }
    }
    
    
    @IBAction func recordButton(_ sender: Any) {
        statusInfo.text = "Recording and Analyzing Audio"
        prepareForRecording()
        createClassificationRequest()
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
    }
    
    //new function
    @objc func timerAction(){
         audioEngine.stop()
         audioEngine.inputNode.removeTap(onBus: 0)
        statusInfo.text = "Recording Stopped"
        print(instumentSet)
        for instr in instumentSet{
            instrumentArray.append(convert(id:instr))
        }
        instrumentTable.reloadData()
        }

}


extension ViewController: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        var temp = [(label: String, confidence: Float)]()
        let sorted = result.classifications.sorted { (first, second) -> Bool in
            return first.confidence > second.confidence
        }
        for classification in sorted {
            let confidence = classification.confidence * 100
            if confidence > 5 {
                temp.append((label: classification.identifier, confidence: Float(confidence)))
            }
        }
        //print(temp)
        let label = temp[0].0
        let conf = temp[0].1
        if (conf > 0.6){
            instumentSet.insert(label)
        }
    }
}

