//
//  example34Tests.swift
//  example34Tests
//
//  Created by Igor Jovcevski on 3.2.23.
//

import XCTest
@testable import WoowaveUITester



class LoginVCProtocolTests: XCTestCase {
    var sut: ViewControllerExample!
    var window: UIWindow!
    var tester:WoowaveUI?

    override func setUp() {
        super.setUp()

        window = UIWindow()
        window.overrideUserInterfaceStyle = .light
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
       // sut = storyboard.instantiateInitialViewController()
        sut = ViewControllerExample(nibName: "ViewControllerExample", bundle: nil)

        window.rootViewController = sut
        window.makeKeyAndVisible()
       
        sleep(2)
    }
    func testExample() throws {
        let expectation = self.expectation(description: "wait")
        DispatchQueue.main.async {
            do {sleep(1)}
            expectation.fulfill()
        }
        waitForExpectations(timeout: 9, handler: nil)
        tester = WoowaveUI()
        let reports = tester?.testVC(sut: sut, window: window).filter{$0.truncated || $0.cutoff || $0.contrast.2 < 3.0}
        reports?.forEach {
          
            let issueString = $0.type + " '\($0.text!.uppercased())' " + ($0.cutoff ? " - CLIPPED " : "") + ($0.truncated ? " TRUNCATED" : "") + ($0.contrast.2 < 3.0 ? " - HAS LOW CONTRAST " : "")
           
            let issue = XCTIssue(type: .performanceRegression, compactDescription: issueString , detailedDescription: "", sourceCodeContext: .init(), associatedError: nil, attachments: [XCTAttachment(image: $0.img!)])
            self.record(issue)
        }
     
      
       
    }

}


class example34Tests: XCTestCase {
//    var sut: UIViewController?
//    var window: UIWindow?
//    var vc2:WoowaveUI?
    
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
    
    override class func setUp() {
        super.setUp()
       // sut = UIViewController()
//        self.window = UIWindow()
//        self.window.overrideUserInterfaceStyle = .light
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        self.sut = storyboard.instantiateInitialViewController()
//
//
//        self.window.rootViewController = sut
//        self.window.makeKeyAndVisible()

        sleep(2)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
