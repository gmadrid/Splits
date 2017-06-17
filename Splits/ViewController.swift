//
//  ViewController.swift
//  Splits
//
//  Created by George Madrid on 6/16/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

extension NSImage {
  convenience init? (cgimage: CGImage?) {
    guard let cgimage = cgimage else { return nil }
    self.init(cgImage: cgimage, size: CGSize.zero)
  }
}

class ViewController: NSViewController {
  @IBOutlet var pageNumberField: NSTextField!
  @IBOutlet var originalImageView: NSImageView!
  @IBOutlet var leftImageView: NSImageView!
  @IBOutlet var rightImageView: NSImageView!
  @IBOutlet var pageNumberSlider: NSSlider!

  @IBOutlet var nextPageButton: NSButton!
  @IBOutlet var prevPageButton: NSButton!
  @IBOutlet var splitButton: NSButton!
  @IBOutlet var progressBar: NSProgressIndicator!

  let disposeBag = DisposeBag()
  var processing = BehaviorSubject(value: false)

  var splitter: PDFSplitter! {
    didSet { self.initializeSplitter() }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  func initializeSplitter() {
    pageNumberSlider.minValue = 1.0
    progressBar.minValue = 1.0
    splitter.numberOfPages_
      .subscribe(onNext: { [weak self] numberOfPages in
        self?.pageNumberSlider.maxValue = Double(numberOfPages)
        self?.progressBar.maxValue = Double(numberOfPages)
      }).dispose()

    splitter.pageImage_
      .map { NSImage(cgimage: $0) }
      .bind(to: originalImageView.rx.image)
      .disposed(by: disposeBag)

    splitter.leftPageImage_
      .map { NSImage(cgimage: $0) }
      .bind(to: leftImageView.rx.image)
      .disposed(by: disposeBag)

    splitter.rightPageImage_
      .map { NSImage(cgimage: $0) }
      .bind(to: rightImageView.rx.image)
      .disposed(by: disposeBag)
    
    // Display the page number.
    Observable.combineLatest(splitter.pageNumber_, splitter.numberOfPages_) {
      return String(format: "Page %d of %d", $0, $1)
      }
      .bind(to:pageNumberField.rx.text)
      .disposed(by: splitter.disposeBag)
    
    // Enable/disable the next/prev buttons based on the page number.
    splitter.pageNumber_
      .map { $0 > 1 }
      .bind(to:prevPageButton.rx.isEnabled)
      .disposed(by: splitter.disposeBag)
    Observable.combineLatest(splitter.pageNumber_, splitter.numberOfPages_) { pageNumber, numberOfPages in
      return pageNumber < numberOfPages
      }
      .bind(to: nextPageButton.rx.isEnabled)
      .disposed(by: splitter.disposeBag)
    
    // Two-way update of the page number slider.
    splitter.pageNumber_.distinctUntilChanged()
      .map { Double($0) }
      .bind(to: pageNumberSlider.rx.value)
      .disposed(by: splitter.disposeBag)
    pageNumberSlider.rx.value.distinctUntilChanged()
      .map { Int($0) }
      .subscribe(onNext: { [weak self] pageNumber in
        self?.splitter.gotoPage(pageNumber)
      })
      .disposed(by: splitter.disposeBag)
    
    // Based on whether split processing is happening.
    // - show/hide split button
    // - enable/disable open file button
    // - hide/show progress indicator
    let p = processing
      .map { !$0 }
      .asDriver(onErrorJustReturn: false)
    processing.asDriver(onErrorJustReturn: false).drive(splitButton.rx.isHidden).disposed(by: disposeBag)
    p.drive(progressBar.rx.isHidden).disposed(by: disposeBag)
  }

  @IBAction func nextPagePushed(_: NSButton) {
    splitter.nextPage()
  }
  
  @IBAction func prevPagePushed(_: NSButton) {
    splitter.prevPage()
  }
  
  @IBAction func splitPushed(_: NSButton) {
    let dialog = NSSavePanel()
    dialog.title = "Save the .pdf file"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.canCreateDirectories = true
    dialog.allowedFileTypes = ["pdf"]
    
    if dialog.runModal() != NSModalResponseOK {
      return
    }
    
    guard let url = dialog.url else {
      return
    }
    
    // TODO: see if NSProgressBar has better RxCocoa support.
    processing.onNext(true)
    progressBar.startAnimation(nil)
    progressBar.doubleValue = 1
    // TODO: when you make this a driver here, what happens to your errors? Can you get them out somehow.
    let split = splitter.split(destUrl: url)
      .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
      .asDriver(onErrorJustReturn: 0)
    
    split
      .drive(onNext: {
        pageNum in self.progressBar.doubleValue = Double(pageNum)
      }, onCompleted: { [weak self] in
        self?.progressBar.stopAnimation(nil)
        
        // It feels very weird to put this here.
        guard let window = self?.view.window else { return }
        let alert = NSAlert()
        alert.messageText = "Split complete"
        alert.beginSheetModal(for: window, completionHandler: { _ in })
      })
      .disposed(by: disposeBag)
    
    split
      .drive(onCompleted: { [weak self] in
        self?.processing.onNext(false)
      })
      .disposed(by: splitter.disposeBag)
  }
}

