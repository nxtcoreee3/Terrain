//
//  TendiesExplorerView.swift
//  Terrain
//
//  Created from Worse-Poster & mond
//

import SwiftUI
import Observation
import AVKit

struct TendiesWallpaper: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let url: String
    let preview: String
    let authors: String?
    let contest: String?
    var category: String = "Cowabunga"

    enum CodingKeys: String, CodingKey {
        case id, name, description, url, preview, authors, contest
    }

    var previewURL: URL? {
        if preview.hasPrefix("https://") {
            return URL(string: preview)
        }
        return URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/\(preview)")
    }

    var downloadURL: URL? {
        if url.hasPrefix("https://") {
            return URL(string: url)
        }
        return URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/\(url)")
    }

    var isVideoPreview: Bool {
        preview.lowercased().hasSuffix(".mp4")
    }
}

private struct NxtcoreWallpaperCatalog: Decodable {
    let packs: [NxtcoreWallpaperPack]
}

private struct NxtcoreWallpaperPack: Decodable {
    let name: String
    let description: String?
    let author: String?
    let versions: [NxtcoreWallpaperVersion]
}

private struct NxtcoreWallpaperVersion: Decodable {
    let label: String
    let previewURL: String
    let downloadURL: String
}

final class TendiesService {
    static let shared = TendiesService()
    
    private let customURL = URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-custom.json")!
    private let appleURL = URL(string: "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-apple.json")!

    func fetchWallpapers() async throws -> [TendiesWallpaper] {
        async let customFetch = fetch(from: customURL, category: "Cowabunga")
        async let appleFetch = fetch(from: appleURL, category: "Apple")

        let (custom, apple) = try await (customFetch, appleFetch)
        let nxtcore = (try? await fetchNxtcoreWallpapers()) ?? []
        return custom + apple + nxtcore
    }

    private func fetchNxtcoreWallpapers() async throws -> [TendiesWallpaper] {
        let sourceURL = URL(string: "https://nxtcoreee3.online/wallpapers/api.json")!
        let (data, response) = try await URLSession.shared.data(from: sourceURL)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        let catalog = try JSONDecoder().decode(NxtcoreWallpaperCatalog.self, from: data)
        var result: [TendiesWallpaper] = []
        for pack in catalog.packs {
            for version in pack.versions {
                let displayName = pack.versions.count > 1 ? "\(pack.name) · \(version.label.capitalized)" : pack.name
                result.append(TendiesWallpaper(
                    id: 1_000_000 + result.count,
                    name: displayName,
                    description: pack.description,
                    url: version.downloadURL,
                    preview: version.previewURL,
                    authors: pack.author,
                    contest: nil,
                    category: "nxtcoreee3"
                ))
            }
        }
        return result
    }

    private func fetch(from url: URL, category: String) async throws -> [TendiesWallpaper] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        var wallpapers = try JSONDecoder().decode([TendiesWallpaper].self, from: data)
        for i in wallpapers.indices {
            wallpapers[i].category = category
        }
        return wallpapers
    }

    func downloadTendies(_ wallpaper: TendiesWallpaper, progress: @escaping (Double) -> Void) async throws -> URL {
        guard let url = wallpaper.downloadURL else {
            throw URLError(.badURL)
        }
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let expectedLength = max(0, response.expectedContentLength)
        var data = Data()
        var receivedLength: Int64 = 0
        for try await byte in bytes {
            try Task.checkCancellation()
            data.append(byte)
            receivedLength += 1
            if receivedLength.isMultiple(of: 65_536) {
                progress(expectedLength > 0 ? min(Double(receivedLength) / Double(expectedLength), 1) : 0)
            }
        }
        progress(1)

        let downloadDir = URL.temporaryDirectory.appendingPathComponent("DownloadedTendies")
        try FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)
        let destination = downloadDir.appendingPathComponent(url.lastPathComponent)
        try data.write(to: destination, options: .atomic)
        return destination
    }
}

struct TendiesExplorerView: View {
    @Binding var tendiesArray: [TendiesObject]
    @Environment(\.dismiss) private var dismiss

    @State private var wallpapers: [TendiesWallpaper] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedWallpaper: TendiesWallpaper?

    let categories = ["All", "Cowabunga", "Apple", "nxtcoreee3"]
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var filteredWallpapers: [TendiesWallpaper] {
        wallpapers.filter { wp in
            let matchesCategory = (selectedCategory == "All") || (wp.category == selectedCategory)
            guard matchesCategory else { return false }
            if searchText.isEmpty { return true }
            return wp.name.localizedCaseInsensitiveContains(searchText) ||
                   (wp.description ?? "").localizedCaseInsensitiveContains(searchText) ||
                   (wp.authors ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if isLoading && wallpapers.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.3)
                        Text("Loading Tendies catalog…")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else if let error = errorMessage, wallpapers.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Couldn't load Tendies")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            loadCatalog()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredWallpapers) { wallpaper in
                                TendiesCard(wallpaper: wallpaper) {
                                    selectedWallpaper = wallpaper
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .navigationTitle("Tendies Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search wallpapers or authors")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        loadCatalog()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(item: $selectedWallpaper) { wp in
                TendiesDetailView(wallpaper: wp) { progress in
                    try await importWallpaper(wp, progress: progress)
                }
            }
            .task {
                if wallpapers.isEmpty {
                    loadCatalog()
                }
            }
        }
    }

    private func loadCatalog() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let items = try await TendiesService.shared.fetchWallpapers()
                await MainActor.run {
                    self.wallpapers = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    @MainActor
    private func importWallpaper(_ wallpaper: TendiesWallpaper, progress: @escaping (Double) -> Void) async throws {
        Haptic.shared.play(.soft)
        let fileURL = try await TendiesService.shared.downloadTendies(wallpaper, progress: progress)
        try Task.checkCancellation()
        guard var object = pbHandler.makeObjectFromTendies(at: fileURL) else {
            throw URLError(.cannotDecodeContentData)
        }
        try Task.checkCancellation()
        object.isOn = true
        withAnimation {
            tendiesArray.append(object)
        }
        Haptic.shared.play(.heavy)
    }
}

private struct TendiesCard: View {
    let wallpaper: TendiesWallpaper
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if wallpaper.isVideoPreview, let url = wallpaper.previewURL {
                        TendiesVideoPreview(url: url, height: 180)
                            .allowsHitTesting(false)
                    } else {
                        AsyncImage(url: wallpaper.previewURL) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color(.secondarySystemBackground)
                                    ProgressView()
                                }
                                .frame(height: 180)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .clipped()
                            case .failure:
                                ZStack {
                                    Color(.secondarySystemBackground)
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(height: 180)
                            @unknown default:
                                Color(.secondarySystemBackground).frame(height: 180)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let authors = wallpaper.authors, !authors.isEmpty {
                        Text(authors)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let desc = wallpaper.description, !desc.isEmpty {
                Text(desc)
            }
        }
    }
}

private struct TendiesVideoPreview: View {
    let url: URL
    let height: CGFloat
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .frame(height: height)
            .task {
                guard player == nil else { return }
                let newPlayer = AVPlayer(url: url)
                newPlayer.isMuted = true
                player = newPlayer
                newPlayer.play()
            }
            .onDisappear {
                player?.pause()
            }
    }
}

private struct TendiesDetailView: View {
    let wallpaper: TendiesWallpaper
    let onImport: (@escaping (Double) -> Void) async throws -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isDownloading = false
    @State private var isDownloaded = false
    @State private var downloadProgress = 0.0
    @State private var downloadTask: Task<Void, Never>?
    @State private var downloadMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        if wallpaper.isVideoPreview, let url = wallpaper.previewURL {
                            TendiesVideoPreview(url: url, height: 380)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(radius: 8)
                        } else {
                            AsyncImage(url: wallpaper.previewURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 380)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 450)
                                        .clipShape(RoundedRectangle(cornerRadius: 22))
                                        .shadow(radius: 8)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                        .frame(height: 300)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(wallpaper.name)
                            .font(.title2.weight(.bold))

                        if let authors = wallpaper.authors, !authors.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "person.circle")
                                    .foregroundStyle(.secondary)
                                Text(authors)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let contest = wallpaper.contest, !contest.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text(contest)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(.capsule)
                        }

                        if let description = wallpaper.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    if isDownloading {
                        VStack(spacing: 12) {
                            Text("Please stay on this page until the wallpaper is fully downloaded.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                            ProgressView(value: downloadProgress)
                                .progressViewStyle(.linear)
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button("Cancel Download", role: .cancel) {
                                downloadTask?.cancel()
                                downloadTask = nil
                                isDownloading = false
                                downloadMessage = "Download canceled."
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    } else if isDownloaded {
                        Label("Downloaded and selected. You can apply it now.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    } else {
                        if let downloadMessage {
                            Text(downloadMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        Button {
                            isDownloading = true
                            downloadProgress = 0
                            downloadMessage = nil
                            downloadTask = Task {
                                do {
                                    try await onImport { value in
                                        downloadProgress = value
                                    }
                                    isDownloaded = true
                                } catch is CancellationError {
                                    downloadMessage = "Download canceled."
                                } catch {
                                    downloadMessage = error.localizedDescription
                                }
                                isDownloading = false
                                downloadTask = nil
                            }
                        } label: {
                            Label("Download & Select Wallpaper", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ConfirmButtonStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle(wallpaper.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        downloadTask?.cancel()
                        dismiss()
                    }
                    .disabled(isDownloading)
                }
            }
            .onDisappear {
                downloadTask?.cancel()
            }
        }
    }
}
