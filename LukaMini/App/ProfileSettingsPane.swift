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
    
    @State private var displayName: String
    @State private var username: String
    @State private var password: String
    @State private var accountLocation: AccountLocation
    
    init(profile: GlucoseProfile, credentials: ProfileCredentials?, appModel: AppModel) {
        self.profile = profile
        self.credentials = credentials
        self.appModel = appModel
        
        self._displayName = State(initialValue: profile.displayName)
        self._username = State(initialValue: credentials?.username ?? "")
        self._password = State(initialValue: credentials?.password ?? "")
        self._accountLocation = State(initialValue: profile.accountLocation)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $displayName, prompt: Text(namePlaceholder))
                    .onSubmit { saveIfValid() }
                
                Toggle("Show in menu bar", isOn: showsInMenuBarBinding)
            } header: {
                Text("User")
            }
            
            Section {
                Picker("Account location", selection: $accountLocation)  {
                    ForEach(AccountLocation.allCases) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                .onChange(of: accountLocation) { _, _ in saveIfValid() }
                
                TextField("Username", text: $username)
                    .onSubmit { saveIfValid() }
                
                SecureField("Password", text: $password)
                    .onSubmit { saveIfValid() }
            } header: {
                Text("Dexcom credentials")
            } footer: {
                Text("Enter the Dexcom username and password of the person whose readings you want to see—not a follower's. Their account must have Dexcom Share turned on with at least one follower. If the username is a phone number, include a country code (for example, +12223334444).")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(profile.displayName.isEmpty ? "User" : profile.displayName)
    }
    
    private var namePlaceholder: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Optional" : trimmed
    }
    
    private var showsInMenuBarBinding: Binding<Bool> {
        Binding {
            profile.showsInMenuBar
        } set: { value in
            appModel.setShowsInMenuBar(id: profile.id, showsInMenuBar: value)
        }
    }
    
    private func saveIfValid() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            return
        }
        
        appModel.updateProfile(
            id: profile.id,
            displayName: displayName,
            username: username,
            password: password,
            accountLocation: accountLocation,
            showsInMenuBar: profile.showsInMenuBar
        )
    }
}
