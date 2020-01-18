//
//  QuizManagementBrowserDelegate.swift
//  EntertainmentPro macOS
//
//  Created by Mark Haskins on 21/10/2018.
//  Copyright © 2018 Mark Haskins. All rights reserved.
//

import Cocoa

extension QuizManagementController: NSBrowserDelegate {

    func rootItem(for browser: NSBrowser) -> Any? {
        browser.setCellClass(BrowserCell.self)
        return root
    }

    func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {

        if let item = item as? BrowserItem {
            return item.childCount
        }
        return 0
    }

    func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {

        if let item = item as? BrowserItem {
            return item.itemChildren[index]
        }
        return ""
    }

    func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {

        if let item = item as? BrowserItem {
            return item.isLeaf
        }
        return true
    }

    func browser(_ browser: NSBrowser, shouldEditItem item: Any?) -> Bool {
        return true
    }

    func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {

        if let item = item as? BrowserItem {
            return item.name
        }
        return "ERR"
    }

    func browser(_ browser: NSBrowser, previewViewControllerForLeafItem item: Any) -> NSViewController? {

        if item is BrowserQuestionItem {
            detailView =
                loadViewController(storyboard: "QuestionDetail", controller: "questionDetail") as? DetailViewController
            detailView?.detailDelegate = self

            return detailView
        }
        return nil
    }

    func browser(_ browser: NSBrowser, didChangeLastColumn oldLastColumn: Int, toColumn column: Int) {

        if column == 3 {
            browser.setWidth(CGFloat(300), ofColumn: 3)
        }
    }

    func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {

        if column == 0 {
            if let item = sender.item(atRow: row, inColumn: column) as? BrowserQuizItem,
                let theCell = cell as? BrowserCell {

                let quiz = item.quiz
                if quiz.id == Int32(UserDefaults.standard.integer(forKey: "quiz.active")) {
                    theCell.image = NSImage(named: NSImage.statusAvailableName)
                } else {
                    theCell.image = nil
                }

                theCell.isLeaf = true
            }
        } else {
            if let theCell = cell as? BrowserCell {
                theCell.image = nil
                theCell.isLeaf = true
            }
        }
    }

    func browser(_ browser: NSBrowser,
                 canDragRowsWith rowIndexes: IndexSet,
                 inColumn column: Int,
                 with event: NSEvent) -> Bool {

        guard column == 1 || column == 2 else { return false }

        return true
    }

    func browser(_ browser: NSBrowser,
                 writeRowsWith rowIndexes: IndexSet,
                 inColumn column: Int,
                 to pasteboard: NSPasteboard) -> Bool {

        guard column == 1 || column == 2 else { return false }

        let row: Int = rowIndexes.last!

        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: self)

        if column == 1 {
            pasteboard.setString(String(row), forType: NSPasteboard.PasteboardType.string)
        } else {
            pasteboard.setString(String(row), forType: NSPasteboard.PasteboardType.string)
        }

        return true
    }

    func browser(_ browser: NSBrowser,
                 validateDrop info: NSDraggingInfo,
                 proposedRow row: UnsafeMutablePointer<Int>,
                 column: UnsafeMutablePointer<Int>,
                 dropOperation: UnsafeMutablePointer<NSBrowser.DropOperation>) -> NSDragOperation {

        return NSDragOperation.move
    }

    func browser(_ browser: NSBrowser,
                 acceptDrop info: NSDraggingInfo,
                 atRow row: Int,
                 column: Int,
                 dropOperation: NSBrowser.DropOperation) -> Bool {

        guard column == 1 || column == 2 else { return false }

        let pboard = info.draggingPasteboard
        let originalRow = Int(pboard.string(forType: NSPasteboard.PasteboardType.string)!)

        var browserItem: BrowserItem
        if column == 1 {
            browserItem = getSelectedQuiz()!
        } else {
            browserItem = getSelectedRound()!
        }

        browserItem.itemChildren.move(at: originalRow!, to: row)

        if column == 1 {
            let quizItem = browserItem as? BrowserQuizItem
            updateRoundsPositions(quizId: quizItem!.quiz.id, browserItems: browserItem.itemChildren)
        } else {
            let roundItem = browserItem as? BrowserRoundItem
            updateQuestionsPositions(roundId: roundItem!.round.id, browserItems: browserItem.itemChildren)
        }

        quizBrowser.reloadColumn(column)

        return true
    }
}
