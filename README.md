# CineFile

CineFile is an iOS application for tracking movies you've watched and want to watch. Keep a personal movie library, manage your watchlist, and discover new films.

## Features

- **Movie Library**: Track movies you've watched with details like director, year, rating, and more
- **Watchlist**: Save movies you want to watch for later
- **Search**: Find new movies to add to your collection
- **Movie Details**: View comprehensive information about each movie
- **Settings**: Customize your app experience

## Technology Stack

- Swift
- SwiftUI
- Combine framework
- Async/Await for network calls
- MVVM Architecture

## Getting Started

### Prerequisites

- Xcode 13.0 or later
- iOS 15.0 or later
- Swift 5.5 or later

### Installation

1. Clone this repository
2. Open `CineFile.xcodeproj` in Xcode
3. Build and run on your iOS device or simulator

## Project Structure

- **Models**: Data structures representing movie information
- **ViewModels**: Business logic and data management
- **Views**: User interface components
- **Services**: Network and data persistence layers (to be implemented)

## API Integration

This app is designed to work with The Movie Database (TMDB) API. To use the API:

1. Get an API key from [TMDB](https://www.themoviedb.org/documentation/api)
2. Enter your API key in the Settings screen

### TMDB Attribution

This product uses the TMDB API but is not endorsed or certified by TMDB.

See our [Privacy Policy](PRIVACY.md).

## Future Enhancements

- User reviews and notes
- Movie recommendations based on viewing history
- Offline access to movie data
- Social sharing features
- Custom lists and collections

## License

This project is available under the MIT License.

## Acknowledgments

- Movie data provided by The Movie Database (TMDB)
- Icons from SF Symbols
