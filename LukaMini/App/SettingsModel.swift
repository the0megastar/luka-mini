//
//  SettingsModel.swift
//  LukaMini
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsModel {
    private let appModel: AppModel
    
    var selectedPane: SettingsPane?
    var isAddingUser = false
    var isShowingDeleteAlert = false
    var isShowingNotificationPermissionAlert = false
    
    var userToDelete: GlucoseProfile.ID?
    var deleteAlertProfileName: String {
        guard let id = userToDelete,
              let model = appModel.model(for: id) else {
            return "this user"
        }
        return model.displayName.isEmpty ? "this user" : model.displayName
    }
    
    init(appModel: AppModel) {
        self.appModel = appModel
        self.selectedPane = appModel.profileModels.isEmpty ? nil : .general
    }
    
    func selectInitialPane() {
        if selectedPane == nil {
            selectedPane = appModel.profileModels.isEmpty ? nil : .general
        }
    }
    
    func reconcileSelection(with profileIDs: [GlucoseProfile.ID]) {
        guard case .profile(let id) = selectedPane else { return }
        if !profileIDs.contains(id) {
            selectedPane = profileIDs.first.map { .profile($0) } ?? .general
        }
    }
    
    func deleteProfile(id: GlucoseProfile.ID) {
        appModel.removeProfile(id: id)
        selectedPane = appModel.profileModels.first.map { .profile($0.id) } ?? .general
        userToDelete = nil
    }
    
    func requestDeleteProfile(id: GlucoseProfile.ID) {
        userToDelete = id
        isShowingDeleteAlert = true
    }
    
    func confirmDelete() {
        guard let id = userToDelete else { return }
        deleteProfile(id: id)
    }
    
    func openNotificationSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let destination = "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)"
        if let url = URL(string: destination) {
            NSWorkspace.shared.open(url)
        }
    }
}

enum SettingsPane: Hashable, Identifiable {
    case general
    case profile(GlucoseProfile.ID)
    
    var id: Self { self }
}
