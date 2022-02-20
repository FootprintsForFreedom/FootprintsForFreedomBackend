//
//  EditableTextRepositoryTests.swift
//
//
//  Created by niklhut on 14.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension EditableObjectRepositoryModel: Equatable {
    public static func == (lhs: EditableObjectRepositoryModel, rhs: EditableObjectRepositoryModel) -> Bool {
        lhs.id == rhs.id
    }
}

final class EditableTextRepositoryTests: AppTestCase {
    var user: UserAccountModel!
    
    override func setUp() async throws {
        app = try await createTestApp()
        let user = UserAccountModel(name: "Test", email: "test@example.com", school: "Test School", password: "MySecure3", verified: false, role: .user)
        try await user.create(on: app.db)
        self.user = user
    }
    
    func testEditableTextRepositoryStartsEmpty() async throws {
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        try await editableTextRepository.load(on: app.db)
        
        XCTAssertNotNil(editableTextRepository.id)
        XCTAssertTrue(editableTextRepository.isEmpty)
        XCTAssertNil(editableTextRepository.current)
        XCTAssertNil(editableTextRepository.last)
    }
    
    func testAppend() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...100).map { String($0) }
        XCTAssertEqual(values.count, 100)
        var editableTextObjectIds = [UUID]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            editableTextObjectIds.append(newEditableTextObject.id!)
        }
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in editableTextObjectIds {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testRemoveLast() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // remove a value from the db and the confirmation array
        let removedValue = try await editableTextRepository.remove(preliminaryEditableTextObjects.last!, on: app.db)
        let confirmRemovedValue = preliminaryEditableTextObjects.removeLast()
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(preliminaryEditableTextObjects.count, values.count - 1)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)

            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testRemoveCurrentAndFirst() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // remove a value from the db and the confirmation array
        let removedValue = try await editableTextRepository.remove(preliminaryEditableTextObjects.first!, on: app.db)
        let confirmRemovedValue = preliminaryEditableTextObjects.removeFirst()
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(preliminaryEditableTextObjects.count, values.count - 1)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count - 1)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testRemoveCurrentAndLast() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // set the last node to also be the current node
        editableTextRepository.currentProperty.id = editableTextRepository.lastProperty.id
        try await editableTextRepository.update(on: app.db)
        
        // remove a value from the db and the confirmation array
        let removedValue = try await editableTextRepository.remove(preliminaryEditableTextObjects.last!, on: app.db)
        let confirmRemovedValue = preliminaryEditableTextObjects.removeLast()
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(preliminaryEditableTextObjects.count, values.count - 1)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.last)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testRemoveOnlyNode() async throws {
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        let firstAndLastValue = "1"
        let node = EditableObjectModel<String>(value: firstAndLastValue, userId: user.id!)
        let firstAndLastEditableTextObject = try await editableTextRepository.append(node, on: app.db)
        XCTAssertEqual(firstAndLastEditableTextObject.value, firstAndLastValue)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, firstAndLastEditableTextObject)
        XCTAssertEqual(editableTextRepository.last, firstAndLastEditableTextObject)
        
        try await editableTextRepository.remove(firstAndLastEditableTextObject, on: app.db)
        XCTAssertTrue(editableTextRepository.isEmpty)
        XCTAssertNil(editableTextRepository.current)
        XCTAssertNil(editableTextRepository.last)
    }
    
    func testRemoveMiddleNode() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // select a random value which is not the first or the last to be removed
        let indexOfEditableTextObjectToRemove = Int.random(in: 1..<preliminaryEditableTextObjects.count - 1)
        XCTAssertGreaterThan(indexOfEditableTextObjectToRemove, 0)
        XCTAssertLessThan(indexOfEditableTextObjectToRemove, preliminaryEditableTextObjects.count)
        // remove a value from the db and the confirmation array
        let removedValue = try await editableTextRepository.remove(preliminaryEditableTextObjects[indexOfEditableTextObjectToRemove], on: app.db)
        let confirmRemovedValue = preliminaryEditableTextObjects.remove(at: indexOfEditableTextObjectToRemove)
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(preliminaryEditableTextObjects.count, values.count - 1)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testRemoveAll() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // get the object entries in the db bevor creating new Objects
        let initialEditableObjectsCount = try await EditableObjectModel<String>
            .query(on: app.db)
            .count()
        
        // create editableTextObjects and store there database ids
        let values = (1...50).map { String($0) }
        XCTAssertEqual(values.count, 50)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // change the current node to be in the middle
        let objectInMiddleIndex = Int(preliminaryEditableTextObjects.count / 2)
        editableTextRepository.currentProperty.id = try preliminaryEditableTextObjects[objectInMiddleIndex].requireID()
        try await editableTextRepository.update(on: app.db)
        
        // Check the new objects were created on the db
        let intermediateEditableObjectsCount = try await EditableObjectModel<String>
            .query(on: app.db)
            .count()
        XCTAssertGreaterThan(intermediateEditableObjectsCount, initialEditableObjectsCount)
        XCTAssertEqual(intermediateEditableObjectsCount, initialEditableObjectsCount + values.count)
        
        try await editableTextRepository.removeAll(on: app.db)
        try await editableTextRepository.load(on: app.db)
        
        // Check the list is correct
        XCTAssertNotNil(editableTextRepository.id)
        XCTAssertTrue(editableTextRepository.isEmpty)
        XCTAssertNil(editableTextRepository.current)
        XCTAssertNil(editableTextRepository.last)
        
        // Check that the entries have been removed on the db
        let finalEditableObjectsCount = try await EditableObjectModel<String>
            .query(on: app.db)
            .count()
        XCTAssertEqual(initialEditableObjectsCount, finalEditableObjectsCount)
    }
    
    func testIncrementCurrent() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, preliminaryEditableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, preliminaryEditableTextObjects.last)
        
        // increment the current node
        try await editableTextRepository.incrementCurrent(on: app.db)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects[1])
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testIncrementCurrentFailsWhenCurrentIsLast() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // set the last node to also be the current node
        editableTextRepository.currentProperty.id = editableTextRepository.lastProperty.id
        try await editableTextRepository.update(on: app.db)
        
        // Check the list is set up correctly
        try await editableTextRepository.load(on: app.db)
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, preliminaryEditableTextObjects.last)
        XCTAssertEqual(editableTextRepository.last, preliminaryEditableTextObjects.last)
        
        // increment the current node and expect it to fail
        do {
            try await editableTextRepository.incrementCurrent(on: app.db)
            XCTFail("Expected to fail since there is no next value to be the new current value")
        } catch {
            XCTAssertEqual(error as! LinkedListError, LinkedListError.noNextValue)
        }
    }
    
    func testIncrementCurrentFailsWhenListIsEmpty() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // increment the current node and expect it to fail
        do {
            try await editableTextRepository.incrementCurrent(on: app.db)
            XCTFail("Expected to fail since the list is empty")
        } catch {
            XCTAssertEqual(error as! LinkedListError, LinkedListError.noNextValue)
        }
    }
    
    func testSwap() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...100).map { String($0) }
        XCTAssertEqual(values.count, 100)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // select two random values which are not the first or the last to be swapped
        let firstIndexToSwap = Int.random(in: 1..<preliminaryEditableTextObjects.count - 1)
        var firstNodeToSwap = preliminaryEditableTextObjects[firstIndexToSwap]
        XCTAssertGreaterThan(firstIndexToSwap, 0)
        XCTAssertLessThan(firstIndexToSwap, preliminaryEditableTextObjects.count)
        let secondIndexToSwap = Int.random(in: 1..<preliminaryEditableTextObjects.count - 1)
        var secondNodeToSwap = preliminaryEditableTextObjects[secondIndexToSwap]
        XCTAssertGreaterThan(secondIndexToSwap, 0)
        XCTAssertLessThan(secondIndexToSwap, preliminaryEditableTextObjects.count)
        
        // swap the to nodes on the db and in the control array
        try await editableTextRepository.swap(&firstNodeToSwap, &secondNodeToSwap, on: app.db)
        preliminaryEditableTextObjects.swapAt(firstIndexToSwap, secondIndexToSwap)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testSwapFirstAndLast() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // select two random values which are not the first or the last to be swapped
        let firstIndexToSwap = 0
        var firstNodeToSwap = preliminaryEditableTextObjects[firstIndexToSwap]
        let secondIndexToSwap = preliminaryEditableTextObjects.count - 1
        var secondNodeToSwap = preliminaryEditableTextObjects[secondIndexToSwap]
        
        // swap the to nodes on the db and in the control array
        try await editableTextRepository.swap(&firstNodeToSwap, &secondNodeToSwap, on: app.db)
        preliminaryEditableTextObjects.swapAt(firstIndexToSwap, secondIndexToSwap)
        XCTAssertEqual(preliminaryEditableTextObjects.first!.value, "10")
        XCTAssertEqual(preliminaryEditableTextObjects.last!.value, "1")
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
    
    func testSwapObjectsNextToEachother() async throws {
        // initialize editable text repository and save it to db
        let editableTextRepository = EditableObjectRepositoryModel<String>()
        try await editableTextRepository.save(on: app.db)
        
        // create editableTextObjects and store there database ids
        let values = (1...10).map { String($0) }
        XCTAssertEqual(values.count, 10)
        var preliminaryEditableTextObjects = [EditableObjectModel<String>]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableTextObject = try await editableTextRepository.append(node, on: app.db)
            preliminaryEditableTextObjects.append(newEditableTextObject)
        }
        
        // select two random values which are not the first or the last to be swapped
        var firstIndexToSwap = 3
        var firstNodeToSwap = preliminaryEditableTextObjects[firstIndexToSwap]
        var secondIndexToSwap = firstIndexToSwap + 1
        var secondNodeToSwap = preliminaryEditableTextObjects[secondIndexToSwap]
        
        // swap the to nodes on the db and in the control array
        try await editableTextRepository.swap(&firstNodeToSwap, &secondNodeToSwap, on: app.db)
        preliminaryEditableTextObjects.swapAt(firstIndexToSwap, secondIndexToSwap)
        
        // load the editableTextObjects from the db
        var editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
        
        // swap back
        // select two random values which are not the first or the last to be swapped
        firstIndexToSwap = secondIndexToSwap
        firstNodeToSwap = preliminaryEditableTextObjects[firstIndexToSwap]
        secondIndexToSwap = firstIndexToSwap - 1
        secondNodeToSwap = preliminaryEditableTextObjects[secondIndexToSwap]
        
        // swap the to nodes on the db and in the control array
        try await editableTextRepository.swap(&firstNodeToSwap, &secondNodeToSwap, on: app.db)
        preliminaryEditableTextObjects.swapAt(firstIndexToSwap, secondIndexToSwap)
        
        // load the editableTextObjects from the db
        editableTextObjects = [EditableObjectModel<String>]()
        for id in preliminaryEditableTextObjects.map({ $0.id! }) {
            let editableTextObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableTextObjects.append(editableTextObject!)
        }
        XCTAssertEqual(editableTextObjects.count, values.count)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableTextRepository.isEmpty)
        XCTAssertEqual(editableTextRepository.current, editableTextObjects.first)
        XCTAssertEqual(editableTextRepository.last, editableTextObjects.last)
        
        // check all links are valid
        for (index, editableTextObject) in editableTextObjects.enumerated() {
            try await editableTextObject.load(on: app.db)
            if editableTextObject == editableTextObjects.first {
                XCTAssertNil(editableTextObject.previous)
                XCTAssertNil(editableTextObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableTextObjects[index - 1]
                XCTAssertEqual(editableTextObject.previous, expectedPreviousNode)
            }
            if editableTextObject == editableTextObjects.last {
                XCTAssertNil(editableTextObject.next)
            } else {
                let expectedNextNode = editableTextObjects[index + 1]
                XCTAssertEqual(editableTextObject.next, expectedNextNode)
            }
        }
    }
}