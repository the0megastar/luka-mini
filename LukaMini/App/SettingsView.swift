//
//  SettingsView.swift
//  LukaMini
//

import AppKit
import SwiftUI

struct SettingsView: View {
    let appModel: AppModel
    @Bindable var loginHelper: LoginItemHelper
    
    @State private var settingsModel: SettingsModel
    @State private var isShowingAddUserSheet = false
    
    init(appModel: AppModel, loginHelper: LoginItemHelper) {
        self.appModel = appModel
        self.loginHelper = loginHelper
        self._settingsModel = State(initialValue: SettingsModel(appModel: appModel))
    }
    
    var body: some View {
        Group {
            if appModel.profileModels.isEmpty {
                OnboardingView(appModel: appModel)
            } else {
                settingsContent
            }
        }
    }
    
    private var settingsContent: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            detailPane
        }
        .frame(minWidth: 700, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    toggleSidebar()
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Sidebar")
            }
        }
        .onAppear {
            settingsModel.selectInitialPane()
        }
        .onChange(of: appModel.profileModels.map(\.id)) { _, ids in
            settingsModel.reconcileSelection(with: ids)
        }
        .sheet(isPresented: $isShowingAddUserSheet) {
            AddUserSheet(appModel: appModel)
        }
        .alert("Delete User?", isPresented: $settingsModel.isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                settingsModel.confirmDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(settingsModel.deleteAlertProfileName) from Luka Mini and deletes the saved Dexcom credentials for this user.")
        }
        .alert("Notifications Are Disabled", isPresented: $settingsModel.isShowingNotificationPermissionAlert) {
            Button("Open Notification Settings") {
                settingsModel.openNotificationSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow notifications for Luka Mini in System Settings, then try again.")
        }
    }
    
    private var sidebar: some View {
        List(selection: $settingsModel.selectedPane) {
            Label("General", systemImage: "gearshape")
                .tag(SettingsPane.general)
            
            Section("Users") {
                ForEach(appModel.profileModels) { model in
                    Label {
                        Text(model.displayName)
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                    }
                    .tag(SettingsPane.profile(model.id))
                    .contextMenu {
                        Button("Delete User") {
                            settingsModel.requestDeleteProfile(id: model.id)
                        }
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        let model = appModel.profileModels[index]
                        settingsModel.requestDeleteProfile(id: model.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isShowingAddUserSheet = true
                } label: {
                    Label("Add User", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Add User")
            }
        }
    }
    
    @ViewBuilder
    private var detailPane: some View {
        if let selectedPane = settingsModel.selectedPane {
            switch selectedPane {
            case .general:
                GeneralSettingsPane(
                    loginHelper: loginHelper,
                    profileCount: appModel.profileModels.count,
                    onNotificationPermissionDenied: {
                        settingsModel.isShowingNotificationPermissionAlert = true
                    }
                )
            case .profile(let id):
                if let model = appModel.model(for: id) {
                    ProfileSettingsPane(
                        profile: model.profile,
                        credentials: appModel.credentials(for: id),
                        appModel: appModel
                    )
                    .id(id)
                }
            }
        } else {
            ContentUnavailableView(
                "No Selection",
                systemImage: "sidebar.left",
                description: Text("Select a settings pane from the sidebar")
            )
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil
        )
    }
}
