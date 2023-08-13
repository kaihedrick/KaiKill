import SwiftUI
import UIKit

struct ContentView: View {
    @State private var domain: String = ""
    @State private var blacklist: [String] = []
    @StateObject private var context = Context()

    var body: some View {
        VStack {
            Text("Domain Blacklist")
                .font(.title)
                .padding()

            TextField("Enter domain", text: $domain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Block Domain") {
                blockDomain()
            }
            .padding()

            Button("Import Blacklist") {
                context.importBlacklist()
            }
            .padding()

            List(blacklist, id: \.self) { blockedDomain in
                Text(blockedDomain)
            }
        }
        .padding()
    }
    
    func blockDomain() {
        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isValidDomain(trimmedDomain) && !blacklist.contains(trimmedDomain) {
            blacklist.append(trimmedDomain)
            domain = ""
        }
    }
    
    func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = #"^www\.[a-zA-Z0-9-]+\.[a-z]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        return predicate.evaluate(with: domain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView {
    class Context: NSObject, ObservableObject, UIDocumentPickerDelegate {
        @Published var blacklist: [String] = []

        func importBlacklist() {
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text"], in: .import)
            documentPicker.delegate = self
            UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                do {
                    let fileContent = try String(contentsOf: url)
                    let domains = fileContent.components(separatedBy: .newlines)
                    blacklist.append(contentsOf: domains)
                } catch {
                    print("Error reading file: \(error)")
                }
            }
        }
    }
}
