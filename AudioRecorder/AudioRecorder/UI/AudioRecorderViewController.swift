import UIKit
import SnapKit
import Combine

class AudioRecorderViewController: UIViewController {

    // MARK: - Properties
    
    private let viewModel: AudioRecorderViewModelType = AudioRecorderViewModel(audioRecorder: AudioRecorder(),
                                                                               audioPlayer: AudioPlayer())
    private var cancellables = Set<AnyCancellable>()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        label.backgroundColor = .gray
        label.text = "00:00:00"
        return label
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 50
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.clipsToBounds = false
        return button
    }()
    
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 50
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.clipsToBounds = false
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 50
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.clipsToBounds = false
        button.backgroundColor = .red
        button.setTitle("Stop", for: .normal)

        return button
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = .black
        label.text = "Duration: 00:00"
        return label
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        view.addSubview(timerLabel)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(playButton)
        view.addSubview(durationLabel)
        
        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(50)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        startButton.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        stopButton.snp.makeConstraints { make in
            make.top.equalTo(startButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        playButton.snp.makeConstraints { make in
            make.top.equalTo(stopButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(playButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }
    
    private func updateRecordButtonAppearance(state: RecordingState) {
        let recordingColor = UIColor.red.withAlphaComponent(0.5)
        let normalColor = UIColor.green
        
        switch state {
        case .start:
            startButton.backgroundColor = normalColor
            startButton.setTitle("Start", for: .normal)
            startButton.removePulse()
            self.playButton.isEnabled = true
        case .paused:
            startButton.backgroundColor = recordingColor
            startButton.setTitle("Pause", for: .normal)
            startButton.pulsate()
            self.playButton.isEnabled = false
        case .resume:
            startButton.backgroundColor = normalColor
            startButton.setTitle("Resume", for: .normal)
            startButton.removePulse()
            self.playButton.isEnabled = false
        case .stop:
            stopButton.backgroundColor = .gray
            stopButton.setTitle("Stop", for: .normal)
            self.playButton.isEnabled = true
        }
    }
    
    private func updatePlayButtonAppearance(state: PlayingState) {
        let playingColor = UIColor.blue.withAlphaComponent(0.1)
        let normalColor = UIColor.green
        
        switch state {
        case .play:
            playButton.backgroundColor = normalColor
            playButton.setTitle("Play", for: .normal)
            self.durationLabel.text = "Duration: 00:00"
            playButton.removePulse()
            self.startButton.isEnabled = true
        case .stop:
            playButton.backgroundColor = playingColor
            playButton.setTitle("Stop", for: .normal)
            playButton.pulsate()
            self.startButton.isEnabled = false
        case .none:
            playButton.backgroundColor = normalColor
            playButton.setTitle("Play", for: .normal)
            playButton.removePulse()
            self.startButton.isEnabled = true
        }
    }
    
    // MARK: - Bindings
    
    private func bindViewModel() {
        // Bindings for ViewModel
        
        viewModel.outputs.formattedCurrentTimeSubject
            .sink { [weak self] timeString in
                self?.timerLabel.text = timeString
            }
            .store(in: &cancellables)
        
        viewModel.outputs.recordingButtonState
            .sink { [weak self] state in
                self?.updateRecordButtonAppearance(state: state)
            }
            .store(in: &cancellables)
        
        viewModel.outputs.playButtonState
            .sink { [weak self] state in
                self?.updatePlayButtonAppearance(state: state)
            }
            .store(in: &cancellables)
        
        viewModel.outputs.playingDurationSubject
            .sink { [weak self] duration in
                self?.durationLabel.text = "Duration \(duration)"
            }
            .store(in: &cancellables)
        
    }
    
    // MARK: - Button Actions
    
    @objc private func startButtonTapped() {
        viewModel.inputs.startRecording()
    }
    
    @objc private func stopButtonTapped() {
        viewModel.inputs.stopRecording()
    }
    
    @objc private func playButtonTapped() {
        viewModel.inputs.playRecording()
    }
}

// MARK: - UIButton Extensions for Animation (Optional)

extension UIButton {
    func pulsate() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.6
        pulse.fromValue = 0.95
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: "pulse")
    }
    
    func removePulse() {
        layer.removeAllAnimations()
    }
}
