# LinkPeer: System Design & App Flow

This document outlines the complete system architecture, data flow, and user journey for **LinkPeer**. The application uses a hybrid backend approach (Firebase + Supabase) to leverage the best of both platforms: Firebase for seamless Google Authentication, and Supabase for robust relational data and serverless Edge Functions.

---

## 1. High-Level System Architecture

The overarching architecture is event-driven and heavily relies on Riverpod for state management on the client-side.

```mermaid
graph TD
    %% Client Layer
    subgraph Client [Client Application - Flutter]
        UI[UI / Widgets]
        State[State Management / Riverpod]
        Local[Local Cache / SharedPreferences]
        
        UI <--> State
        State <--> Local
    end

    %% Firebase Layer
    subgraph Firebase [Firebase]
        Auth[Firebase Auth]
        Firestore[(Firestore)]
    end

    %% Supabase Layer
    subgraph Supabase [Supabase]
        DB[(PostgreSQL Database)]
        Storage[Object Storage / CDN]
        Edge[Edge Functions]
    end
    
    %% External Services
    FCM[Google FCM]

    %% Connections
    State -->|Google Sign-In| Auth
    State -->|User Profiles| Firestore
    State -->|Posts, Comments, Likes| DB
    State -->|Images & Documents| Storage
    
    DB -.->|Database Triggers Webhook| Edge
    Edge -->|Push Payload| FCM
    FCM -->|Push Notification| Client
```

---

## 2. Authentication & Onboarding Flow

Authentication dictates what screens the user has access to. The app uses `AuthGate` as the central traffic controller to route users based on their Firebase Auth status and profile completion state.

```mermaid
stateDiagram-v2
    [*] --> AuthGate: App Launch
    
    AuthGate --> LoginScreen: User is NULL
    LoginScreen --> GoogleOAuth: Tap "Continue with Google"
    GoogleOAuth --> AuthGate: Success (Tokens Received)
    
    AuthGate --> CheckProfile: User exists
    CheckProfile --> MainShell: profile_completed == true
    CheckProfile --> OnboardingScreen: profile_completed == false
    
    OnboardingScreen --> UpdateProfile: Fills out Branch, Year, etc.
    UpdateProfile --> MainShell: Success
    
    MainShell --> [*]: User interacts with Feed
```

---

## 3. Data Flow: Creating a Post with an Image

When a user creates a new post with a file/image attachment, the client coordinates between Supabase Storage and the PostgreSQL database.

```mermaid
sequenceDiagram
    participant User
    participant FlutterApp
    participant SupabaseStorage
    participant SupabaseDB

    User->>FlutterApp: Taps "Post" with Image
    activate FlutterApp
    
    FlutterApp->>SupabaseStorage: Uploads Image (multipart form)
    activate SupabaseStorage
    SupabaseStorage-->>FlutterApp: Returns Public URL
    deactivate SupabaseStorage
    
    FlutterApp->>SupabaseDB: Insert Post (title, content, public_url)
    activate SupabaseDB
    SupabaseDB-->>FlutterApp: 201 Created
    deactivate SupabaseDB
    
    FlutterApp->>User: Pops Screen & Updates Feed
    deactivate FlutterApp
```

---

## 4. Notification Flow (Serverless Event-Driven)

This flow ensures that API keys remain secure and that notifications are handled independently of the client application logic.

```mermaid
sequenceDiagram
    participant UserA as User A (Client)
    participant SupabaseDB as Supabase DB
    participant Trigger as Postgres Trigger
    participant Edge as Edge Function
    participant FCM as Firebase Cloud Messaging
    participant UserB as User B (Target)

    UserA->>SupabaseDB: Inserts Comment
    SupabaseDB->>SupabaseDB: App Inserts Notification Row
    
    SupabaseDB->>Trigger: AFTER INSERT event fired
    Trigger->>Edge: pg_net HTTP Webhook (Payload)
    
    activate Edge
    Edge->>Edge: Queries Target User's FCM Token
    Edge->>Edge: Generates Google OAuth JWT
    Edge->>FCM: HTTP v1 POST Request
    deactivate Edge
    
    activate FCM
    FCM->>UserB: Delivers Push Notification
    deactivate FCM
```

---

## 5. Directory Mapping to Architecture

- **`lib/main.dart`**: Entry point; initializes Firebase, Supabase, Theme, and Notification Services.
- **`lib/core/auth_gate.dart`**: Implements the Authentication & Onboarding state machine.
- **`lib/core/google_auth_controller.dart`**: Bridges the gap between the Google SDK and Firebase Auth.
- **`lib/core/providers/`**: Holds Riverpod logic that caches data from Firestore (users) and Supabase (posts) locally.
- **`supabase/functions/`**: Holds the server-side TypeScript code for the event-driven notification flow.
