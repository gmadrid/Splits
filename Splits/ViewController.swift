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
  convenience init?(cgimage: CGImage?) {
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
  
  var splitter: PDFSplitter!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    initializeSplitter()
  }
  
  func initializeSplitter() {
    splitter = (self.view.window?.windowController?.document as? Document)?.splitter

    pageNumberSlider.minValue = 1.0
//    progressBar.minValue = 1.0
    splitter.numberOfPages_.subscribe(onNext: { [weak self] numberOfPages in
      self?.pageNumberSlider.maxValue =  Double(numberOfPages)
//      self?.progressBar.maxValue = Double(numberOfPages)
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
  }

}

