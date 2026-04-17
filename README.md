💬 supabase_chat
A real-time one-to-one chat app built with Flutter & Supabase
Flutter   |   Supabase   |   Dart   |   Realtime

📖 About
supabase_chat is a full-stack mobile chat application built entirely with Flutter on the frontend and Supabase as the backend. It demonstrates real-world usage of Supabase's authentication, PostgreSQL database, and realtime capabilities in a production-style Flutter app.
This project was built to explore full-stack mobile development without needing a separate backend service — Supabase handles everything.

✨ Features
User Authentication — Secure sign up and login with email/password via Supabase Auth
One-to-One Chat — Private messaging between two users
Realtime Messaging — Messages appear instantly using Supabase Realtime subscriptions
Message Persistence — All messages stored in Supabase PostgreSQL database
Session Management — Users stay logged in across app restarts

🛠️ Tech Stack


🚀 Getting Started
Prerequisites
Flutter SDK installed (3.0+)
A free Supabase account at supabase.com
Dart SDK
1. Clone the repository
git clone https://github.com/abhilashh/supabase_chat.git
cd supabase_chat
2. Set up Supabase
Create a new project at supabase.com
Go to Settings → API and copy your Project URL and anon/public key
Run the following SQL in the Supabase SQL editor to create the required tables:
create table messages (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references auth.users not null,
  receiver_id uuid references auth.users not null,
  content text not null,
  created_at timestamp with time zone default now()
);

-- Enable Realtime
alter publication supabase_realtime add table messages;
3. Add your Supabase credentials
Create a .env file or update the Supabase initialization in lib/main.dart:
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
4. Run the app
flutter pub get
flutter run

📁 Project Structure
lib/
├── main.dart              # App entry point & Supabase init
├── screens/
│   ├── login_screen.dart  # Auth: login & signup
│   ├── chat_list.dart     # List of conversations
│   └── chat_screen.dart   # One-to-one chat UI
└── services/
    └── supabase_service.dart  # Database & realtime logic

🔐 Security Notes
Row Level Security (RLS) should be enabled on the messages table so users can only read their own messages
The anon key is safe to use in the Flutter app — never use the service role key
Never commit your .env file or hardcode credentials in source code

🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

📄 License
MIT License — feel free to use this project as a starter for your own chat applications.

Built with ❤️ using Flutter & Supabase
