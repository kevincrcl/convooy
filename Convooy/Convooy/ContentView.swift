import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Welcome Tab
            WelcomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Welcome")
                }
            
            // Map Tab
            MapBoxMapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
        }
        .accentColor(Color(red: 0.4, green: 0.2, blue: 0.6)) // Dark purple from logo
    }
}

struct WelcomeView: View {
    var body: some View {
        ZStack {
            // Background gradient inspired by the logo's vibrant colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.89), // Light cream background
                    Color(red: 0.95, green: 0.93, blue: 0.86)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image("ConvooyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // App name with fun styling
                Text("Convooy")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.6)) // Dark purple from logo
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                
                // Tagline
                Text("Navigate with Style")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.8))
                    .opacity(0.8)
                
                Spacer()
                
                // Fun decorative elements inspired by the logo's starburst
                HStack(spacing: 20) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.4, blue: 0.2), // Bright orange
                                        Color(red: 1.0, green: 0.2, blue: 0.2)  // Bright red
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 12, height: 12)
                            .scaleEffect(1.0 + Double(index) * 0.1)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: index
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
