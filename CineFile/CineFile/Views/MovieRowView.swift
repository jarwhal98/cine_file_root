import SwiftUI

struct MovieRowView: View {
    let movie: Movie
    
    var body: some View {
    HStack(spacing: 15) {
            // Movie poster
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 90)
            .accessibilityIgnoresInvertColors()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(1)
                
                let yearText = String(movie.year)
                Text(verbatim: movie.director.isEmpty ? yearText : "\(yearText) • \(movie.director)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Runtime and genres
                if movie.runtime > 0 || !movie.genres.isEmpty {
                    let parts: [String] = [
                        movie.runtime > 0 ? "\(movie.runtime) min" : nil,
                        !movie.genres.isEmpty ? movie.genres.joined(separator: ", ") : nil
                    ].compactMap { $0 }
                    Text(parts.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Status indicators
                HStack(spacing: 10) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", movie.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // Watched status
                    if movie.watched {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Watched")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Watchlist status
                    if movie.inWatchlist {
                        HStack(spacing: 2) {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Watchlist")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.card)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .padding(.vertical, 6)
    }
}
