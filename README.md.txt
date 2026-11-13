-----------------------------------------------------------------------
# Virtual Wardrobe App with Augmented Reality - ARdrobe

ARdrobe allows users to manage their wardrobe and try on outfits 
through a simple 2D camera overlay feature.

-----------------------------------------------------------------------

## Features 
- Upload and organize wardrobe items
- View clothes by category, color, type, and season
- Favorite your favorite outfits
- Try on outfits using 2D camera overlay
- Search their wardrobe by category, color, type and season
- Save important events in calendar and preplan outfits
- Get real-time weather-based outfit suggestions based on user lcoation
- Update location to receive live weather-based suggestions

-----------------------------------------------------------------------

## Tech Stack 
- Flutter (Frontend and Camera overlay)
- Firebase Firestore (Database for wardrobe items)
- Cloudinary (Storage for uploaded images)

-----------------------------------------------------------------------

## How It Works 
1. Users create account and logs into ARdrobe
2. Users save their current location in the app 
3. Users upload clothes as images (JPEG/PNG) 
4. App stores images securely in Cloudinary
5. Users select clothes and open the camera
6. Selected clothes are shown as a 2D overlay on the camera view
7. Users can adjust (zoom and drag) the clothes on their body

-----------------------------------------------------------------------

## Setup Instructions 🛠️
1. Download the project 
2. Open the project in VS Code
3. Install Flutter dependencies:
   ```bash
   flutter pub get
4. Setup Firebase project and Cloudinary account
4. Build and run the app
   flutter run
-----------------------------------------------------------------------
This project is developed for academic purposes.
All rights reserved © 2025 Aisha Nahas.
-----------------------------------------------------------------------