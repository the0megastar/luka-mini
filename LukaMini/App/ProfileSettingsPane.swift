//
//  ProfileSettingsPane.swift
//  LukaMini
//

import Dexcom
import SwiftUI

struct ProfileSettingsPane: View {
    let profile: GlucoseProfile
    let credentials: ProfileCredentials?
    let appModel: AppModel
    
    @State private var editor: ProfileEditor
    @State private var original: ProfileEditor
    
    init(profile: GlucoseProfile, credentials: ProfileCredentials?, appModel: AppModel) {
        self.profile = profile
        self.credentials = credentials
        self.appModel = appModel
        
        let editor = ProfileEditor(profile: profile, credentials: credentials)
        self._editor = State(initialValue: editor)
        self._original = State(initialValue: editor)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name:", text: $editor.displayName, prompt: Text(editor.namePlaceholder))
                
                Toggle("Show in menu bar", isOn: showsInMenuBarBinding)
            } header: {
                Text("User")
            }
            
            Section {
                Picker("Account Location:", selection: $editor.accountLocation) {
                    ForEach(AccountLocation.allCases) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                
                TextField("Username:", text: $editor.username)
                
                SecureField("Password:", text: $editor.password)
            } header: {
                Text("Dexcom Credentials")
            } footer: {
                Text("Enter the Dexcom username and password of the person whose readings you want to see—not a follower's. Their account must have Dexcom Share turned on with at least one follower. If the username is a phone number, include a country code (for example, +12223334444).")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(profile.displayName.isEmpty ? "User" : profile.displayName)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(!canSave)
            }
        }
    }
    
    private var canSave: Bool {
        editor.canSave && editor != original
    }
    
    private var showsInMenuBarBinding: Binding<Bool> {
        Binding {
            editor.showsInMenuBar
        } set: { value in
            editor.showsInMenuBar = value
            original.showsInMenuBar = value
            appModel.setShowsInMenuBar(id: profile.id, showsInMenuBar: value)
        }
    }
    
    private func saveProfile() {
        appModel.updateProfile(
            id: profile.id,
            displayName: editor.displayName,
            username: editor.username,
            password: editor.password,
            accountLocation: editor.accountLocation,
            showsInMenuBar: editor.showsInMenuBar
        )
        original = editor
    }
}

struct ProfileEditor: Equatable {
    var displayName: String
    var username: String
    var password: String
    var accountLocation: AccountLocation
    var showsInMenuBar: Bool
    
    var canSave: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }
    
    var namePlaceholder: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Optional" : trimmed
    }
    
    init(profile: GlucoseProfile, credentials: ProfileCredentials?) {
        self.displayName = profile.displayName
        self.username = credentials?.username ?? ""
        self.password = credentials?.password ?? ""
        self.accountLocation = profile.accountLocation
        self.showsInMenuBar = profile.showsInMenuBar
    }
}
