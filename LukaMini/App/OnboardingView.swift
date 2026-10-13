//
//  OnboardingView.swift
//  LukaMini
//

import AppKit
import Dexcom
import SwiftUI

struct OnboardingView: View {
    let appModel: AppModel
    
    @State private var accountLocation: AccountLocation = .usa
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case username
        case password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                }
                
                Text("Welcome to Luka Mini")
                    .font(.largeTitle.weight(.bold))
                
                Text("Sign in with Dexcom to show glucose readings in your menu bar.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Form {
                Section {
                    TextField("Username:", text: $username)
                        .focused($focusedField, equals: .username)
                        .onSubmit { focusedField = .password }
                    
                    SecureField("Password:", text: $password)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            Task { await signIn() }
                        }
                    
                    Picker("Region:", selection: $accountLocation) {
                        ForEach(AccountLocation.allCases) { location in
                            Text(location.displayName).tag(location)
                        }
                    }
                } footer: {
                    Text("Enter the Dexcom username and password of the person whose readings you want to see—not a follower's. Their account must have Dexcom Share turned on with at least one follower. If the username is a phone number, include a country code (for example, +12223334444).")
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            HStack(spacing: 12) {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    Task { await signIn() }
                } label: {
                    if isSigningIn {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Signing In…")
                        }
                        .frame(minWidth: 100)
                    } else {
                        Text("Sign In")
                            .frame(minWidth: 100)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSignIn)
            }
            
            Spacer()
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 480)
        .onAppear {
            focusedField = .username
        }
    }
    
    private var canSignIn: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !isSigningIn
    }
    
    @MainActor
    private func signIn() async {
        guard canSignIn else { return }
        errorMessage = nil
        isSigningIn = true
        defer { isSigningIn = false }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let client = DexcomClient(
            username: trimmedUsername,
            password: password,
            accountLocation: accountLocation
        )
        
        do {
            _ = try await client.getGlucoseReadings(duration: .init(value: 24, unit: .hours))
        } catch let error as DexcomError {
            switch error.code {
            case .accountPasswordInvalid, .authenticateMaxAttemptsExceeed:
                errorMessage = "Incorrect username or password."
            case .invalidArgument:
                errorMessage = "That username doesn't look right. If it's a phone number, format it like +12223334444."
            case .sessionIdNotFound, .sessionNotValid, .none:
                errorMessage = error.message ?? "Dexcom rejected the sign-in. Double-check your credentials and region."
            }
            return
        } catch {
            errorMessage = "Couldn't reach Dexcom. Check your internet connection and try again."
            return
        }
        
        appModel.addProfile(
            displayName: "",
            username: trimmedUsername,
            password: password,
            accountLocation: accountLocation,
            showsInMenuBar: true
        )
    }
}
