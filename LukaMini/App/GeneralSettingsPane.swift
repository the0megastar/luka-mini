//
//  GeneralSettingsPane.swift
//  LukaMini
//

import SwiftUI

struct GeneralSettingsPane: View {
    @Bindable var loginHelper: LoginItemHelper
    @AppStorage(.useMMOLKey) private var useMMOL = false
    @AppStorage(.graphRangeKey) private var graphRange: GraphRange = .threeHours
    @AppStorage(.showNamesForMultipleUsersKey) private var showNamesForMultipleUsers = true
    @AppStorage(.colorMenuBarReadingKey) private var colorMenuBarReading = false
    @AppStorage(.lowerGlucoseThresholdKey) private var lowerGlucoseThreshold = GlucoseRange.defaultLowerBound
    @AppStorage(.upperGlucoseThresholdKey) private var upperGlucoseThreshold = GlucoseRange.defaultUpperBound
    @AppStorage(.outOfRangeNotificationsKey) private var outOfRangeNotifications = false
    @AppStorage(.useServerForReadingsKey) private var useServerForReadings = true
    
    let profileCount: Int
    var onNotificationPermissionDenied: () -> Void
    
    var body: some View {
        Form {
            Section {
                Picker("Graph Range:", selection: $graphRange) {
                    ForEach(GraphRange.allCases) { range in
                        Text(range.abbreviatedName).tag(range)
                    }
                }
                
                Picker("Units:", selection: $useMMOL) {
                    Text("mg/dL").tag(false)
                    Text("mmol/L").tag(true)
                }
                .pickerStyle(.segmented)
                
                if profileCount > 1 {
                    Toggle("Show names for multiple users", isOn: $showNamesForMultipleUsers)
                }
                
                Toggle("Color glucose reading", isOn: $colorMenuBarReading)
                
                LabeledContent("Target Range:") {
                    HStack(spacing: 6) {
                        TextField(
                            "",
                            value: displayedLowerGlucoseThreshold,
                            format: thresholdFormat
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .accessibilityLabel("Lower glucose threshold")
                        
                        Text("to")
                            .foregroundStyle(.secondary)
                        
                        TextField(
                            "",
                            value: displayedUpperGlucoseThreshold,
                            format: thresholdFormat
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .accessibilityLabel("Upper glucose threshold")
                        
                        Text(useMMOL ? "mmol/L" : "mg/dL")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Menu bar")
            }
            
            Section {
                Toggle("Launch at login", isOn: $loginHelper.isEnabled)
            } header: {
                Text("Startup")
            }
            
            Section {
                Toggle("Fetch from Luka servers", isOn: $useServerForReadings)
            } header: {
                Text("Data source")
            } footer: {
                Text("Fetch readings from the Luka server, which caches them while the Luka iOS app runs a Live Activity. This reduces direct requests to Dexcom. Falls back to Dexcom automatically when no cached readings are available.")
            }
            
            Section {
                Toggle(
                    "Notify outside target range",
                    isOn: outOfRangeNotificationsBinding
                )
            } header: {
                Text("Notifications")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onChange(of: lowerGlucoseThreshold) { _, newValue in
            lowerGlucoseThreshold = max(1, min(newValue, upperGlucoseThreshold - 1))
        }
        .onChange(of: upperGlucoseThreshold) { _, newValue in
            upperGlucoseThreshold = max(lowerGlucoseThreshold + 1, min(newValue, 1_000))
        }
    }
    
    private var displayedLowerGlucoseThreshold: Binding<Double> {
        glucoseThresholdBinding(for: $lowerGlucoseThreshold)
    }
    
    private var displayedUpperGlucoseThreshold: Binding<Double> {
        glucoseThresholdBinding(for: $upperGlucoseThreshold)
    }
    
    private var thresholdFormat: FloatingPointFormatStyle<Double> {
        .number
            .grouping(.never)
            .precision(.fractionLength(useMMOL ? 1 : 0))
    }
    
    private func glucoseThresholdBinding(for threshold: Binding<Int>) -> Binding<Double> {
        Binding {
            let value = Double(threshold.wrappedValue)
            return useMMOL ? value * .mmolConversionFactor : value
        } set: { value in
            let mgdl = useMMOL ? value / .mmolConversionFactor : value
            threshold.wrappedValue = Int(mgdl.rounded())
        }
    }
    
    private var outOfRangeNotificationsBinding: Binding<Bool> {
        Binding {
            outOfRangeNotifications
        } set: { isEnabled in
            if isEnabled {
                Task {
                    let authorized = await GlucoseNotificationManager.shared.requestAuthorization()
                    if authorized {
                        outOfRangeNotifications = true
                    } else {
                        onNotificationPermissionDenied()
                    }
                }
            } else {
                outOfRangeNotifications = false
            }
        }
    }
}
