//
//  QuizManagementController.swift
//  EntertainmentPro macOS
//
//  Created by Mark Haskins on 27/09/2018.
//  Copyright © 2018 Mark Haskins. All rights reserved.
//

import Cocoa
import SpriteKit

class QuizManagementController: GameAdminViewController {

    @IBOutlet weak var quizBrowser: QuizBrowser!

    let quizDao = QuizDao()
    let quizRoundDao = QuizRoundDao()
    let roundDao = RoundDao()
    let roundQuestionDao = RoundQuestionDao()
    let questionDao = QuestionDao()

    var currentSheet: NSViewController!

    var standardQuestionSheetController: QuestionStandardSheetViewController!
    var multiQuestionSheetController: QuestionMultipleSheetViewController!
    var impossibleQuestionSheetController: QuestionImpossibleSheetViewController!

    var quizSheetController: QuizSheetViewController!
    var roundSheetController: RoundSheetViewController!

    var detailView: DetailViewController!

    let root = BrowserRootItem(name: "Root")

    override func viewDidLoad() {

        splashImage = SKSpriteNode(imageNamed: "bingo_splash")

        super.viewDidLoad()

        quizBrowser.registerForDraggedTypes([NSPasteboard.PasteboardType.string])

        loadQuizzes()
    }

    override func showSplashScene() {
        // not used
    }

    override func setupToolbar() {

        self.toolbar.displayMode = NSToolbar.DisplayMode.iconAndLabel

        add(NSToolbarItem.Identifier.space)

        add(NSToolbarItem.Identifier.quizMQuizGroup)
        add(NSToolbarItem.Identifier.space)

        add(NSToolbarItem.Identifier.quizMRoundGroup)
        add(NSToolbarItem.Identifier.space)

        add(NSToolbarItem.Identifier.quizMQuestionGroup)

        disable(NSToolbarItem.Identifier.quizMQuizDelete, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
        disable(NSToolbarItem.Identifier.quizMQuizActivate, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
        disable(NSToolbarItem.Identifier.quizMRoundAdd, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
        disable(NSToolbarItem.Identifier.quizMRoundDelete, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
        disable(NSToolbarItem.Identifier.quizMQuestionAdd, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
        disable(NSToolbarItem.Identifier.quizMQuestionDelete, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
    }

    @objc func columnClicked(_ sender: Any) {

        let col = quizBrowser.selectedColumn

        switch col {
        case 0:
            enable(NSToolbarItem.Identifier.quizMQuizDelete, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            enable(NSToolbarItem.Identifier.quizMQuizActivate, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            enable(NSToolbarItem.Identifier.quizMRoundAdd, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            disable(NSToolbarItem.Identifier.quizMRoundDelete, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            disable(NSToolbarItem.Identifier.quizMQuestionAdd, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
            disable(NSToolbarItem.Identifier.quizMQuestionDelete, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
        case 1:
            disable(NSToolbarItem.Identifier.quizMQuizDelete, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            disable(NSToolbarItem.Identifier.quizMQuizActivate, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            enable(NSToolbarItem.Identifier.quizMRoundAdd, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            enable(NSToolbarItem.Identifier.quizMRoundDelete, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            enable(NSToolbarItem.Identifier.quizMQuestionAdd, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
            disable(NSToolbarItem.Identifier.quizMQuestionDelete, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
        case 2:
            disable(NSToolbarItem.Identifier.quizMQuizDelete, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            disable(NSToolbarItem.Identifier.quizMQuizActivate, inGroup: NSToolbarItem.Identifier.quizMQuizGroup)
            disable(NSToolbarItem.Identifier.quizMRoundAdd, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            disable(NSToolbarItem.Identifier.quizMRoundDelete, inGroup: NSToolbarItem.Identifier.quizMRoundGroup)
            enable(NSToolbarItem.Identifier.quizMQuestionAdd, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
            enable(NSToolbarItem.Identifier.quizMQuestionDelete, inGroup: NSToolbarItem.Identifier.quizMQuestionGroup)
        default:
            break
        }
    }

//    @IBAction func edit(_ sender: Any) {
//
//        quizBrowser.selectRow(quizBrowser.clickedRow, inColumn: quizBrowser.clickedColumn)
//
//        switch quizBrowser.clickedColumn {
//        case 0:
//            showQuizSheet(isUpdate: true)
//        case 1:
//            showRoundSheet(isUpdate: true)
//        case 2:
//            editQuestion()
//        default:
//            break
//        }
//    }
}

extension QuizManagementController: DetailViewControllerDelegate {

    func editQuestion() {

        guard let questionItem = getSelectedQuestion() else { return }
        let question = questionItem.question

        switch question.type {
        case 1:
            showQuestionSheet(questionType: 1, isUpdate: true)
        case 2:
            showQuestionSheet(questionType: 2, isUpdate: true)
        case 3:
            showQuestionSheet(questionType: 3, isUpdate: true)
        default:
            break
        }
    }
}

extension QuizManagementController: QuizManagementToolbarDelegate {

    func createQuiz(_ sender: Any?) {
        showQuizSheet(isUpdate: false)
    }

    func deleteQuiz(_ sender: Any?) {

        guard let quizItem = getSelectedQuiz() else { return }

        root.removeChild(child: quizItem)
        quizDao.delete(quiz: quizItem.quiz)
        quizBrowser.reloadColumn(0)
    }

    func activateQuiz(_ sender: Any?) {

        guard let quizItem = getSelectedQuiz() else { return }

        let quiz = quizItem.quiz
        UserDefaults.standard.set(quiz.id, forKey: "quiz.active")
        quizBrowser.reloadColumn(0)
    }

    func createRound(_ sender: Any?) {
        showRoundSheet(isUpdate: false)
    }

    func deleteRound(_ sender: Any?) {

        guard let quizItem = getSelectedQuiz() else { return }
        guard let roundItem = getSelectedRound() else { return }

        let round = roundItem.round
        let quiz = quizItem.quiz

        // first delete the questions
        let questionIds = roundQuestionDao.getQuestionIdsfor(roundId: round.id)
        questionDao.deleteQuestions(questionIds: questionIds)

        // next remove the references to the questions from the round
        roundQuestionDao.deleteRoundQuestions(roundId: round.id)

        // now remove the reference of the round from the quiz
        quizRoundDao.deleteQuizRound(quizId: quiz.id, roundId: round.id)

        // finally delete the round
        roundDao.delete(round: round)

        quizItem.removeChild(child: roundItem)
        quizBrowser.reloadColumn(1)
        if quizItem.childCount == 0 {
            quizBrowser.reloadColumn(0)
        }
    }

    func addStandard(_ sender: Any?) {
        showQuestionSheet(questionType: 1, isUpdate: false)
    }

    func addMultiChoice(_ sender: Any?) {
        showQuestionSheet(questionType: 2, isUpdate: false)
    }

    func addImpossible(_ sender: Any?) {
        showQuestionSheet(questionType: 3, isUpdate: false)
    }

    func deleteQuestion(_ sender: Any?) {

        guard let questionItem = getSelectedQuestion() else { return }
        guard let roundItem = getSelectedRound() else { return }

        let round = roundItem.round
        let question = questionItem.question

        roundQuestionDao.deleteRoundQuestion(roundId: round.id, questionId: question.id)
        questionDao.deleteQuestion(questionId: question.id)

        roundItem.removeChild(child: questionItem)

        quizBrowser.reloadColumn(2)
        if roundItem.childCount == 0 {
            quizBrowser.reloadColumn(1)
        }
    }
}
