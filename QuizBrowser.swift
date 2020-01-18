import Cocoa

class QuizBrowser: NSBrowser {

    override func doDoubleClick(_ sender: Any?) {

        super.doDoubleClick(sender)

        guard let indexPath = self.selectionIndexPath else { return }

        self.editItem(at: indexPath, with: nil, select: true)
    }
}
