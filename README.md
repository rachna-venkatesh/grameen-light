# Grameen-Light: Smart Village Streetlight Monitoring System

Grameen-Light is a Flutter-based Android application developed to support smart village streetlight monitoring. The app allows citizens to report streetlight issues, track repair status, view pole locations on Google Maps, and monitor energy-saving analytics.

## Problem Statement

In many villages, streetlights may remain ON during the day due to manual errors, causing electricity wastage. Sometimes fused or damaged streetlights remain unrepaired because the Panchayat or responsible authority is not informed on time. Grameen-Light solves this by enabling citizens to report streetlight issues digitally.

## Features

- User Login and Signup using Firebase Authentication
- Interactive Dashboard for streetlight status monitoring
- Google Maps integration with pole markers
- Color-coded pole status:
  - Green: Working
  - Red: Fused
  - Orange: Repairing
  - Yellow/Cyan: Burning in Day
- Direct marker-based reporting from map
- Quick streetlight complaint reporting
- Automatic complaint ID generation
- Firebase Firestore cloud storage
- Persistent pole status after app restart
- Repair Tracker with Mark Fixed and Delete options
- Analytics dashboard showing:
  - Total poles
  - Working lights
  - Pending repairs
  - Daytime wastage
  - Energy saved
- AI-style repair suggestions based on issue type
- Modern dark neon UI suitable for smart village monitoring

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Firebase Firestore
- Google Maps API
- Android
- VS Code

## Project Workflow

1. User logs into the application.
2. User views the dashboard and pole map.
3. User selects a pole and reports an issue.
4. Complaint is stored in Firebase Firestore.
5. Repair team can mark the complaint as fixed.
6. Pole status and analytics update automatically.
7. Data remains persistent even after app restart.

## Impact

Grameen-Light supports:

- Smart village infrastructure
- Faster streetlight repair reporting
- Reduced daytime energy wastage
- Improved public safety at night
- Digital communication between citizens and local authorities


## Future Enhancements

- Current location tracking
- Admin dashboard for Panchayat users
- Push notifications for repair updates
- Real AI-based complaint prioritization
- Real GPS-based pole registration

## Author

Developed by Rachna Venkatesh as part of Android App Development using GenAI internship project.