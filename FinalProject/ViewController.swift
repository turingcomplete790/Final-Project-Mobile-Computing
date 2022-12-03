//
//  ViewController.swift
//  FinalProject
//
//  Created by Faisal(Zack) Ashour on 11/25/22.
//

import UIKit
import AVKit
import SoundAnalysis

class ViewController: UIViewController {
    private func convert(id: String) -> String {
        let mapping = ["cel" : "drum", "cla" : "clarinet", "flu" : "flute",
                       "gac" : "acoustic guitar", "gel" : "electric guitar",
                       "org" : "organ", "pia" : "piano", "sax" : "saxophone",
                       "tru" : "trumpet", "vio" : "violin", "voi" : "human voice"]
        return mapping[id] ?? id
    }
    @IBOutlet weak var statusInfo: UILabel!
    @IBOutlet weak var PlayButton: UIButton!
    @IBOutlet weak var TimeStamp: UILabel!
    @IBOutlet weak var StopButton: UIButton!
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = MySoundClassifier()
    var streamAnalyzer: SNAudioStreamAnalyzer!
    let queue = DispatchQueue(label: "com.zackashour.FinalProject")

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func RecordButton(_ sender: UIButton) {
        prepareForRecording()
        createClassificationRequest()
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
        print(temp)
    }
}

