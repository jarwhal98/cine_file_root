import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("showAdultContent") private var showAdultContent = false
    @AppStorage("defaultTab") private var defaultTab = 0
    
    @State private var apiKey = UserDefaults.standard.string(forKey: "tmdbApiKey") ?? ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Use System Theme", isOn: $useSystemTheme)
                    
                    if !useSystemTheme {
                        Toggle("Dark Mode", isOn: $useDarkMode)
                    }
                }
                
                Section(header: Text("Content")) {
                    Toggle("Show Adult Content", isOn: $showAdultContent)
                    
                    Picker("Default Tab", selection: $defaultTab) {
                        Text("Movies").tag(0)
                        Text("Watchlist").tag(1)
                        Text("Search").tag(2)
                        Text("Settings").tag(3)
                    }
                }
                
                Section(header: Text("API")) {
                    TextField("TMDB API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: apiKey) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "tmdbApiKey")
                        }
                    
                    Button("Save API Key") {
                        UserDefaults.standard.set(apiKey, forKey: "tmdbApiKey")
                    }
                    .disabled(apiKey.isEmpty)
                }

                Section(header: Text("Import Lists")) {
                    if viewModel.isImporting {
                        VStack(alignment: .leading) {
                            ProgressView(value: viewModel.importProgress)
                            Text("Importing... \(Int(viewModel.importProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Import NYTimes 100 (21st Century)") {
                            viewModel.importNYT21FromCSV()
                        }
                        Button("Import AFI 100 (2007)") {
                            viewModel.importAFIFromCSV()
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Text("About CineFile")
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                }
                
                Section {
                    Button("Clear Cache") {
                        // Clear cache implementation
                    }
                    
                    Button("Reset All Settings") {
                        useSystemTheme = true
                        useDarkMode = false
                        showAdultContent = false
                        defaultTab = 0
                        apiKey = ""
                        UserDefaults.standard.set("", forKey: "tmdbApiKey")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CineFile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("CineFile is your personal movie tracking app. Keep track of what you've watched, what you want to watch, and discover new movies.")
                    .font(.body)
                
                Text("Features:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "film", title: "Track Movies", description: "Keep a list of all the movies you've watched")
                    FeatureRow(icon: "bookmark", title: "Watchlist", description: "Save movies you want to watch for later")
                    FeatureRow(icon: "magnifyingglass", title: "Search", description: "Find new movies to add to your collection")
                    FeatureRow(icon: "star", title: "Rate Movies", description: "Rate the movies you've watched")
                }
                
                Text("Credits:")
                    .font(.headline)
                    .padding(.top)
                
                Text("Movie data provided by The Movie Database (TMDB)")
                    .font(.caption)
                
                Text("© 2025 Your Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
