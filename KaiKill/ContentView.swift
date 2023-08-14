import SwiftUI
import UIKit

struct DomainModel: Identifiable {
    let id = UUID()
    let domain: String
    var isEnabled: Bool
}

class Context: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var blacklist: [DomainModel] = []

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
                let uniqueDomains = Array(Set(domains))
                blacklist.append(contentsOf: uniqueDomains.map { DomainModel(domain: $0, isEnabled: true) })
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @State private var domain: String = ""
    @State private var showAlert = false
    @State private var isProgramEnabled = true
    @StateObject private var contextManager = Context()

    var body: some View {
        VStack {
            Text("Domain Blacklist")
                .font(.title)
                .padding()

            TextField("Enter domain", text: $domain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: domain) { newDomain in
                    updateBlacklist(with: newDomain)
                }
                .padding(.horizontal)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Success"), message: Text("The domain was added successfully!"), dismissButton: .default(Text("OK")))
                }

            Button(action: addDomain) {
                Text("Add Domain")
            }
            .padding()
            .disabled(!isProgramEnabled)

            Button(action: contextManager.importBlacklist) {
                Text("Import Blacklist")
            }
            .padding()
            .disabled(!isProgramEnabled)

            Divider()

            ScrollView {
                DomainList(title: "Individually Blocked Domains", domains: $contextManager.blacklist)
            }
        }
        .padding()

        ToggleProgramButton(isProgramEnabled: $isProgramEnabled)
    }

    func addDomain() {
        guard isProgramEnabled else { return }

        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)

        if isValidDomain(trimmedDomain) && !contextManager.blacklist.contains(where: { $0.domain == trimmedDomain }) {
            contextManager.blacklist.append(DomainModel(domain: trimmedDomain, isEnabled: true))
            domain = ""
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showAlert = false
            }
        }
    }

    func updateBlacklist(with newDomain: String) {
        guard isProgramEnabled else { return }

        let trimmedDomain = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)

        if isValidDomain(trimmedDomain) && !contextManager.blacklist.contains(where: { $0.domain == trimmedDomain }) {
            contextManager.blacklist.append(DomainModel(domain: trimmedDomain, isEnabled: true))
        }
    }

    func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = #"^www\.[a-zA-Z0-9-]+\.[a-z]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        return predicate.evaluate(with: domain)
    }
}

struct DomainList: View {
    let title: String
    @Binding var domains: [DomainModel]

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()

            ForEach(domains) { domain in
                HStack {
                    Text(domain.domain)
                        .foregroundColor(domain.isEnabled ? .black : .gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("|")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 2)
                    Text(domain.isEnabled ? "On" : "Off")
                        .foregroundColor(domain.isEnabled ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onTapGesture {
                            toggleDomain(domain: domain)
                        }
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
    
    func toggleDomain(domain: DomainModel) {
        if let index = domains.firstIndex(where: { $0.id == domain.id }) {
            domains[index].isEnabled.toggle()
        }
    }
}

struct ToggleProgramButton: View {
    @Binding var isProgramEnabled: Bool

    var body: some View {
        Button(action: {
            isProgramEnabled.toggle()
        }) {
            Text(isProgramEnabled ? "Stop" : "Start")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(isProgramEnabled ? Color.red : Color.green)
                .cornerRadius(10)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
