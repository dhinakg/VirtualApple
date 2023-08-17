//
//  InstallViewController.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/21/21.
//

import Cocoa
import Virtualization

@MainActor
class InstallViewController: NSViewController, NSTextFieldDelegate {
	var virtualMachine: VirtualMachine!
	var ipswPathControl: NSPathControl!
	var diskSizeTextField: NSTextField!
	var ecidTextField: NSTextField!
	var serialNumberTextField: NSTextField!
	var installButton: NSButton!
	var installProgressIndicator: NSProgressIndicator!
	var installing = false

	convenience init(virtualMachine: VirtualMachine) {
		self.init()
		self.virtualMachine = virtualMachine
	}

	override func loadView() {
		let view = NSView()

		let ipswLabel = NSTextField(labelWithString: "IPSW:")
		ipswPathControl = NSPathControl()
		ipswPathControl.target = self
		ipswPathControl.action = #selector(ipswSelected(_:))
		ipswPathControl.isEditable = true
		ipswPathControl.pathStyle = .popUp
		let ipswStackView = NSStackView(fixedSizeViews: [ipswLabel, ipswPathControl])
		ipswStackView.alignment = .firstBaseline

		let diskSizeLabel = NSTextField(labelWithString: "Disk size:")
		diskSizeTextField = NSTextField()
		diskSizeTextField.delegate = self
		let diskSizeGBLabel = NSTextField(labelWithString: "GB")
		let diskSizeStackView = NSStackView(fixedSizeViews: [diskSizeLabel, diskSizeTextField, diskSizeGBLabel])
		diskSizeStackView.alignment = .firstBaseline

		let ecidLabel: NSTextField = NSTextField(labelWithString: "ECID:")
		ecidTextField = NSTextField()
		ecidTextField.placeholderString = "Optional"
		ecidTextField.delegate = self
		let ecidStackView = NSStackView(fixedSizeViews: [ecidLabel, ecidTextField])
		ecidStackView.alignment = .firstBaseline

		let serialNumberLabel = NSTextField(labelWithString: "Serial Number:")
		serialNumberTextField = NSTextField()
        serialNumberTextField.placeholderString = "Optional"
		serialNumberTextField.delegate = self
		let serialNumberStackView = NSStackView(fixedSizeViews: [serialNumberLabel, serialNumberTextField])
		serialNumberStackView.alignment = .firstBaseline

		let installStackView = NSStackView(views: [ipswStackView, diskSizeStackView, ecidStackView,
                                                   serialNumberStackView])
		installStackView.orientation = .vertical
		installStackView.fitContents()
		view.addSubview(installStackView)

		let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.keyEquivalent = "\u{1b}"
		view.addSubview(cancelButton)

		installButton = NSButton(title: "Install", target: self, action: #selector(install(_:)))
		installButton.translatesAutoresizingMaskIntoConstraints = false
		installButton.keyEquivalent = "\r"
		view.addSubview(installButton)

		installProgressIndicator = NSProgressIndicator()
		installProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
		installProgressIndicator.maxValue = 1
		installProgressIndicator.isIndeterminate = false
		installProgressIndicator.isHidden = true
		view.addSubview(installProgressIndicator)

		NSLayoutConstraint.activate([
			installStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
			view.trailingAnchor.constraint(equalToSystemSpacingAfter: installStackView.trailingAnchor, multiplier: 1),
			installStackView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
			ecidLabel.trailingAnchor.constraint(equalTo: serialNumberLabel.trailingAnchor),
			diskSizeLabel.trailingAnchor.constraint(equalTo: ecidLabel.trailingAnchor),
			ipswLabel.trailingAnchor.constraint(equalTo: diskSizeLabel.trailingAnchor),
			ipswPathControl.widthAnchor.constraint(equalToConstant: 240),
			diskSizeTextField.widthAnchor.constraint(equalToConstant: 64),
			ecidTextField.widthAnchor.constraint(equalToConstant: 240),
			serialNumberTextField.widthAnchor.constraint(equalToConstant: 128),
			cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
			installButton.leadingAnchor.constraint(equalToSystemSpacingAfter: cancelButton.trailingAnchor, multiplier: 1),
			cancelButton.firstBaselineAnchor.constraint(equalTo: installButton.firstBaselineAnchor),
			installButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
			installButton.topAnchor.constraint(equalToSystemSpacingBelow: installStackView.bottomAnchor, multiplier: 1),
			view.trailingAnchor.constraint(equalToSystemSpacingAfter: installButton.trailingAnchor, multiplier: 1),
			view.bottomAnchor.constraint(equalToSystemSpacingBelow: installButton.bottomAnchor, multiplier: 1),
			installProgressIndicator.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
			cancelButton.leadingAnchor.constraint(equalToSystemSpacingAfter: installProgressIndicator.trailingAnchor, multiplier: 1),
			installButton.centerYAnchor.constraint(equalTo: installProgressIndicator.centerYAnchor),
		])

		validateUI()

		self.view = view
	}

	func validateUI() {
		installButton.title = installing ? "Installing…" : "Install"
		var isValidSerial = true
		if serialNumberTextField.stringValue != "" {
            let serialNumber = unsafeBitCast(NSClassFromString("_VZMacSerialNumber")!, to: _VZMacSerialNumber.Type.self).init(string: serialNumberTextField.stringValue)
			isValidSerial = serialNumber != nil
		}
		var isValidECID = true
        if isValidECID && ecidTextField.stringValue != "" {
			// I should check properly, but whatever
            isValidECID = UInt(ecidTextField.stringValue) != nil && unsafeBitCast(NSClassFromString("VZMacMachineIdentifier")!, to: _VZMacMachineIdentifier.Type.self)._machineIdentifier(ECID: UInt(ecidTextField.stringValue)!, serialNumber: unsafeBitCast(NSClassFromString("_VZMacSerialNumber")!, to: _VZMacSerialNumber.Type.self).init(string: "AAAAAAAAAA")) != nil
		}
        installButton.isEnabled = !installing && ipswPathControl.url != nil && Int(diskSizeTextField.stringValue) != nil && isValidSerial && isValidECID
		installProgressIndicator.isHidden = !installing
		ipswPathControl.isEditable = !installing
		ipswPathControl.isEnabled = !installing
		diskSizeTextField.isEditable = !installing
		diskSizeTextField.isEnabled = !installing
		ecidTextField.isEditable = !installing
		ecidTextField.isEnabled = !installing
		serialNumberTextField.isEditable = !installing
		serialNumberTextField.isEnabled = !installing
	}

	@IBAction func controlTextDidChange(_ obj: Notification) {
		validateUI()
	}

	@IBAction func ipswSelected(_ sender: NSPathControl) {
		validateUI()
	}

	@IBAction func cancel(_ sender: NSButton) {
		dismiss(self)
	}

	@IBAction func install(_ sender: NSButton) {
		installing = true
		validateUI()
		let progressTask = Task {
			while true {
				installProgressIndicator.doubleValue = virtualMachine.installProgress?.fractionCompleted ?? 0
				try await Task.sleep(nanoseconds: 1_000_000_000)
			}
		}
		Task {
			let result = await Task {
				try await virtualMachine.install(ipsw: ipswPathControl.url!, diskSize: Int(diskSizeTextField.stringValue)!, ECID: UInt(ecidTextField.stringValue) ?? 0, serialNumber: serialNumberTextField.stringValue)
				progressTask.cancel()
				(view.window!.sheetParent!.windowController as! WindowController).dismiss(self)
			}.result
			if case let .failure(error) = result {
				await NSAlert(error: error).beginSheetModal(for: view.window!)
				installing = false
				validateUI()
			}
		}
	}
}
