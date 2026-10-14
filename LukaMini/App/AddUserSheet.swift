//
//  AddUserSheet.swift
//  LukaMini
//

import Dexcom
import SwiftUI

struct AddUserSheet: View {
    let appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var accountLocation: AccountLocation = .usa
    @State private var showsInMenuBar = true
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case displayName
        case username
        case password
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $displayName, prompt: Text("Optional"))
                    .focused($focusedField, equals: .displayName)
                    .onSubmit { focusedField = .username }
                
                Toggle("Show in menu bar", isOn: $showsInMenuBar)
            } header: {
                Text("User")
            }
            
            Section {
                Picker("Account location", selection: $accountLocation) {
                    ForEach(AccountLocation.allCases) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                
                TextField("Username", text: $username)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .password }
                
                SecureField("Password", text: $password)
                    .focused($focusedField, equals: .password)
                    .onSubmit { addUser() }
            } header: {
                Text("Dexcom credentials")
            } footer: {
                Text("Enter the Dexcom username and password of the person whose readings you want to see—not a follower's. Their account must have Dexcom Share turned on with at least one follower. If the username is a phone number, include a country code (for example, +12223334444).")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 450, minHeight: 350)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    addUser()
                }
                .disabled(!canAdd)
            }
        }
        .onAppear {
            focusedField = .displayName
        }
    }
    
    private var canAdd: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }
    
    private func addUser() {
        guard canAdd else { return }
        
        appModel.addProfile(
            displayName: displayName,
            username: username,
            password: password,
            accountLocation: accountLocation,
            showsInMenuBar: showsInMenuBar
        )
        
        dismiss()
    }
}
