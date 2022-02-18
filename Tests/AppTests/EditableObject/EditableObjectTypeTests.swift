//
//  EditableObjectTypeTests.swift
//  
//
//  Created by niklhut on 18.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class EditableObjectTypeTests: AppTestCase {
    var user: UserAccountModel!
    
    override func setUp() async throws {
        app = try await createTestApp()
        let user = UserAccountModel(name: "Test", email: "test@example.com", school: "Test School", password: "MySecure3", verified: false, role: .user)
        try await user.create(on: app.db)
        self.user = user
    }
    
    func testEditableObjectSupportsString() async throws {
        // initialize editable text repository and save it to db
        let editableObjectRepository = EditableObjectRepositoryModel<String>()
        try await editableObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let values = (1...100).map { String($0) }
        XCTAssertEqual(values.count, 100)
        var editableObjectIds = [UUID]()
        for value in values {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableObject = try await editableObjectRepository.append(node, on: app.db)
            editableObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableObjects = [EditableObjectModel<String>]()
        for id in editableObjectIds {
            let editableObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableObjects.append(editableObject!)
        }
        XCTAssertEqual(editableObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableObjectRepository.isEmpty)
        XCTAssertEqual(editableObjectRepository.current, editableObjects.first)
        XCTAssertEqual(editableObjectRepository.last, editableObjects.last)
        
        // check all links are valid
        for (index, editableObject) in editableObjects.enumerated() {
            try await editableObject.load(on: app.db)
            if editableObject == editableObjects.first {
                XCTAssertNil(editableObject.previous)
                XCTAssertNil(editableObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableObjects[index - 1]
                XCTAssertEqual(editableObject.previous, expectedPreviousNode)
            }
            if editableObject == editableObjects.last {
                XCTAssertNil(editableObject.next)
            } else {
                let expectedNextNode = editableObjects[index + 1]
                XCTAssertEqual(editableObject.next, expectedNextNode)
            }
        }
    }
    
    func testEditableObjectSupportsIntegers() async throws {
        // initialize editable text repository and save it to db
        let editableObjectRepository = EditableObjectRepositoryModel<Int>()
        try await editableObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let values = (1...100).map { Int($0) }
        XCTAssertEqual(values.count, 100)
        var editableObjectIds = [UUID]()
        for value in values {
            let node = EditableObjectModel<Int>(value: value, userId: user.id!)
            let newEditableObject = try await editableObjectRepository.append(node, on: app.db)
            editableObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableObjects = [EditableObjectModel<Int>]()
        for id in editableObjectIds {
            let editableObject = try await EditableObjectModel<Int>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableObjects.append(editableObject!)
        }
        XCTAssertEqual(editableObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableObjectRepository.isEmpty)
        XCTAssertEqual(editableObjectRepository.current, editableObjects.first)
        XCTAssertEqual(editableObjectRepository.last, editableObjects.last)
        
        // check all links are valid
        for (index, editableObject) in editableObjects.enumerated() {
            try await editableObject.load(on: app.db)
            if editableObject == editableObjects.first {
                XCTAssertNil(editableObject.previous)
                XCTAssertNil(editableObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableObjects[index - 1]
                XCTAssertEqual(editableObject.previous, expectedPreviousNode)
            }
            if editableObject == editableObjects.last {
                XCTAssertNil(editableObject.next)
            } else {
                let expectedNextNode = editableObjects[index + 1]
                XCTAssertEqual(editableObject.next, expectedNextNode)
            }
        }
    }
    
    func testEditableObjectSupportsStructs() async throws {
        struct Location: Codable, Equatable {
            var latitude: Double
            var longitude: Double
        }
        // initialize editable text repository and save it to db
        let editableObjectRepository = EditableObjectRepositoryModel<Location>()
        try await editableObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let values = (1...100).map { Location(latitude: Double($0), longitude: Double($0)) }
        XCTAssertEqual(values.count, 100)
        var editableObjectIds = [UUID]()
        for value in values {
            let node = EditableObjectModel<Location>(value: value, userId: user.id!)
            let newEditableObject = try await editableObjectRepository.append(node, on: app.db)
            editableObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableObjects = [EditableObjectModel<Location>]()
        for id in editableObjectIds {
            let editableObject = try await EditableObjectModel<Location>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableObjects.append(editableObject!)
        }
        XCTAssertEqual(editableObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableObjectRepository.isEmpty)
        XCTAssertEqual(editableObjectRepository.current, editableObjects.first)
        XCTAssertEqual(editableObjectRepository.last, editableObjects.last)
        
        // check all links are valid
        for (index, editableObject) in editableObjects.enumerated() {
            try await editableObject.load(on: app.db)
            if editableObject == editableObjects.first {
                XCTAssertNil(editableObject.previous)
                XCTAssertNil(editableObject.previousProperty.id)
            } else {
                let expectedPreviousNode = editableObjects[index - 1]
                XCTAssertEqual(editableObject.previous, expectedPreviousNode)
            }
            if editableObject == editableObjects.last {
                XCTAssertNil(editableObject.next)
            } else {
                let expectedNextNode = editableObjects[index + 1]
                XCTAssertEqual(editableObject.next, expectedNextNode)
            }
        }
    }
    
    func testEditableObjectSupportsMultipleTypesSimultaneously() async throws {
        // initialize editable text repository and save it to db
        let editableStringObjectRepository = EditableObjectRepositoryModel<String>()
        try await editableStringObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let stringValues = (1...100).map { String($0) }
        XCTAssertEqual(stringValues.count, 100)
        var editableStringObjectIds = [UUID]()
        for value in stringValues {
            let node = EditableObjectModel<String>(value: value, userId: user.id!)
            let newEditableObject = try await editableStringObjectRepository.append(node, on: app.db)
            editableStringObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableStringObjects = [EditableObjectModel<String>]()
        for id in editableStringObjectIds {
            let editableObject = try await EditableObjectModel<String>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableStringObjects.append(editableObject!)
        }
        XCTAssertEqual(editableStringObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableStringObjectRepository.isEmpty)
        XCTAssertEqual(editableStringObjectRepository.current, editableStringObjects.first)
        XCTAssertEqual(editableStringObjectRepository.last, editableStringObjects.last)
        
        // initialize editable text repository and save it to db
        let editableIntObjectRepository = EditableObjectRepositoryModel<Int>()
        try await editableIntObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let intValues = (1...100).map { Int($0) }
        XCTAssertEqual(intValues.count, 100)
        var editableIntObjectIds = [UUID]()
        for value in intValues {
            let node = EditableObjectModel<Int>(value: value, userId: user.id!)
            let newEditableObject = try await editableIntObjectRepository.append(node, on: app.db)
            editableIntObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableIntObjects = [EditableObjectModel<Int>]()
        for id in editableIntObjectIds {
            let editableObject = try await EditableObjectModel<Int>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableIntObjects.append(editableObject!)
        }
        XCTAssertEqual(editableIntObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableIntObjectRepository.isEmpty)
        XCTAssertEqual(editableIntObjectRepository.current, editableIntObjects.first)
        XCTAssertEqual(editableIntObjectRepository.last, editableIntObjects.last)
        
        struct Location: Codable, Equatable {
            var latitude: Double
            var longitude: Double
        }
        // initialize editable text repository and save it to db
        let editableLocationObjectRepository = EditableObjectRepositoryModel<Location>()
        try await editableLocationObjectRepository.save(on: app.db)
        
        // create editableObjects and store there database ids
        let locationValues = (1...100).map { Location(latitude: Double($0), longitude: Double($0)) }
        XCTAssertEqual(locationValues.count, 100)
        var editableLocationObjectIds = [UUID]()
        for value in locationValues {
            let node = EditableObjectModel<Location>(value: value, userId: user.id!)
            let newEditableObject = try await editableLocationObjectRepository.append(node, on: app.db)
            editableLocationObjectIds.append(newEditableObject.id!)
        }
        // load the editableObjects from the db
        var editableLocationObjects = [EditableObjectModel<Location>]()
        for id in editableLocationObjectIds {
            let editableObject = try await EditableObjectModel<Location>
                .query(on: app.db)
                .filter(\.$id == id)
                .first()
            editableLocationObjects.append(editableObject!)
        }
        XCTAssertEqual(editableLocationObjects.count, 100)
        
        // Check the list is set up correctly
        XCTAssertFalse(editableLocationObjectRepository.isEmpty)
        XCTAssertEqual(editableLocationObjectRepository.current, editableLocationObjects.first)
        XCTAssertEqual(editableLocationObjectRepository.last, editableLocationObjects.last)
    }
}
