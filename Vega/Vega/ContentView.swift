import SwiftUI
 
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
 
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Inicio",      systemImage: "house.fill") }
                .tag(AppTab.home)
 
            CalendarView()
                .tabItem { Label("Calendario",  systemImage: "calendar") }
                .tag(AppTab.calendar)
 
            TrackView()
                .tabItem { Label("Seguimiento", systemImage: "plus") }
                .tag(AppTab.tracking)
 
            AnalysisView()
                .tabItem { Label("Análisis",    systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.analysis)
 
            ProfileView()
                .tabItem { Label("Perfil",      systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(Theme.primary)
    }
}
 
enum AppTab {
    case home, calendar, tracking, analysis, profile
}
#Preview{
    ContentView()
}
