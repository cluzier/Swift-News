//
//  ContentView.swift
//  News
//
//  Created by Conner Luzier on 1/24/22.
//

import SwiftUI
import SafariServices

// Grab news data from lil api
let apiURL = "https://api.lil.software/news"

struct News: Codable {
    var articles: [Article]
}

// lil api provides title, date, url, image and source, giving each their types here
struct Article: Codable, Hashable {
    var title: String
    var date: String
    var url: String
    var image: String?
    var source: String
}

struct ContentView: View {
    // declaring variables
    @State var articles: [Article] = []
    @State var loading = true
    @State private var showingAlert = false
    // without the searchText variable, searchable() will not work as expected
    @State private var searchText = ""
    // getting app version from bundle > general > version
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    let date = Text(Date().addingTimeInterval(600), style: .date)
    
    var body: some View {
        NavigationView {
            VStack {
                if self.loading {
                    // show loading screen when loading api data
                    ProgressView()
                } else {
                    List {
                        // loops through the articles fetched from lil api
                        ForEach(articles, id: \.self) { article in
                            ArticleView(article: article)
                        }.onChange(of: searchText) { searchText in
                            // filter the list of articles when searching
                            // need to update this eventually to support live updating search results
                            if !searchText.isEmpty {
                                articles = articles.filter { $0.title.contains(searchText) }
                            } else {
                                loadNews()
                            }
                        }
                        
                        HStack {
                            // display version
                            Text("Developed by Conner Luzier 👨🏼‍💻 " + appVersion!)
                        }
                        .listRowInsets(EdgeInsets())
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color(UIColor.systemGroupedBackground))
                    }
                    .toolbar {
                                ToolbarItem(placement: .principal) {
                                    VStack {
                                        Text("Top Stories")
                                            .foregroundColor(.red)
                                            .font(.largeTitle)
                                            .bold()
                                    }
                                }
                            }
                    
                    // search bar to filter results
                    
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for articles...")
                    
                    // pull down to refresh news articles from api
                    .refreshable {
                        loadNews()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: {
            self.loadNews()
        })
    }
    
    // load news from api
    func loadNews() {
        // forming the url
        let request = URLRequest(url: URL(string: apiURL)!)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(News.self, from: data) {
                    DispatchQueue.main.async {
                        self.articles = decodedResponse.articles
                        self.loading = false
                    }
                    
                    return
                }
            }
        }.resume()
    }
}

// article view is launched when user clicks on an article
struct ArticleView: View {
    // declare variables
    @State var article: Article
    @State var showWebView = false
    
    var body: some View {
        Button(action: { self.showWebView = true }) {
            VStack (alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 16) {
                    ImageView(imageUrl: article.image ?? "")
                        .frame(width: 128, height: 96)
                        .background(Color(UIColor.systemFill))
                        .cornerRadius(4)
                        .clipped()
                    
                    VStack (alignment: .leading, spacing: 6) {
                        Text(article.title)
                            .font(.system(.headline, design: .serif))
                        // need to eventually fix date formatting
                        Text(article.date)
                            .font(.footnote)
                        Text(article.source)
                            .font(.callout)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        // when article is selected, show the web view of the article
        .sheet(isPresented: $showWebView) {
            WebView(url: URL(string: self.article.url)!).edgesIgnoringSafeArea(.all)
        }
    }
}

struct WebView: UIViewControllerRepresentable {
    let url: URL
    // opens the safari controller to view the article using the url fetched from api
    func makeUIViewController(context: UIViewControllerRepresentableContext<WebView>) -> SFSafariViewController {
        let webview = SFSafariViewController(url: url)
        return webview
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<WebView>) {
    }
}

struct ImageView: View {
    @ObservedObject var remoteImageURL: RemoteImageURL
    
    init(imageUrl: String) {
        remoteImageURL = RemoteImageURL(imageURL: imageUrl)
    }
    
    var body: some View {
        Image(uiImage: UIImage(data: self.remoteImageURL.data) ?? UIImage())
            .resizable()
            .scaledToFit()
            .aspectRatio(contentMode: .fill)
    }
}

class RemoteImageURL: ObservableObject {
    @Published var data = Data()
    
    // if the url image is an unsecure url, add 'https' to allow for secure access, if the url is invalid, return
    init(imageURL: String) {
        guard let url = URL(string: imageURL.replacingOccurrences(of: "http://", with: "https://")) else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let _ = response {
                DispatchQueue.main.async {
                    self.data = data
                }
            }
        }.resume()
    }
}
