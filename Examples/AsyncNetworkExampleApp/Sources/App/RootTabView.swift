//
//  RootTabView.swift
//  AsyncNetworkExampleApp
//
//  Created by JunyoungJung on 2026/03/29.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BasicsView()
            }
            .tabItem {
                Label("Basics", systemImage: "network")
            }

            NavigationStack {
                RecipesView()
            }
            .tabItem {
                Label("Recipes", systemImage: "slider.horizontal.3")
            }

            NavigationStack {
                MonitorView()
            }
            .tabItem {
                Label("Monitor", systemImage: "waveform.path.ecg")
            }
        }
    }
}
