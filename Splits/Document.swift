//
//  Document.swift
//  Splits
//
//  Created by George Madrid on 6/16/17.
//  Copyright © 2017 George Madrid. All rights reserved.
//

import Cocoa

class Document: NSDocument {
  var splitter: PDFSplitter!

  override init() {
    super.init()
    // Add your subclass-specific initialization here.
  }

  override class func autosavesInPlace() -> Bool {
    return true
  }

  override func makeWindowControllers() {
    // Returns the Storyboard that contains your Document window.
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController

    addWindowController(windowController)

    // The ViewController requires a splitter to continue. If this fails, we
    // probably crash.
    if let viewController = windowController.contentViewController as? ViewController,
      let splitter = splitter {
      viewController.splitter = splitter
    }
  }

  override func data(ofType _: String) throws -> Data {
    // Insert code here to write your document to data of the specified type.
    // If outError != nil, ensure that you create and set an appropriate error
    // when returning nil.
    // You can also choose to override fileWrapperOfType:error:,
    // writeToURL:ofType:error:, or
    // writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from url: URL, ofType _: String) throws {
    splitter = try PDFSplitter(url: url)
  }
}
