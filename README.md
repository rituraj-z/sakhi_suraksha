# Sakhi Suraksha: Real-Time Safety Companion for Women Travelers (Built with Flutter)

Sakhi Suraksha is a **cross-platform mobile application** meticulously engineered with **Flutter** to provide real-time assistance and enhanced safety for women during travel. In an increasingly interconnected world, ensuring personal safety, especially in unfamiliar environments, is paramount. Sakhi Suraksha addresses this critical need by offering a comprehensive suite of features designed to empower users with immediate support and peace of mind.

## Problem Statement

The lack of immediate, reliable assistance in threatening situations during travel poses a significant risk to women. Existing solutions often lack the integration of real-time communication, AI-powered guidance, and seamless accessibility across various devices, leaving users vulnerable. Sakhi Suraksha aims to bridge this gap by providing a holistic, proactive safety solution, leveraging Flutter's ability to build performant and beautiful native applications from a single codebase.

---

## Features

* **Emergency SOS Button:** A prominent, easily accessible button for instant emergency alerts.
* **Shake-to-Trigger SOS:** Users can rapidly activate emergency protocols by shaking their device three times, enabling discrete and swift action.
* **Automated Emergency Notifications:** Upon SOS activation, the app automatically sends an SMS to pre-configured emergency contacts, including the user's name, the nature of the situation, and their precise real-time location.
* **Secure Emergency Contact Management:** Users can securely add, edit, and manage their emergency contacts within the application.
* **Proximity-Based Safe Place Search:** Integrates with location services to identify and display nearby safe zones, such as police stations, hospitals, or trusted establishments.
* **AI-Powered Situational Assistance:** Powered by **Gemini AI**, an integrated chat assistant provides real-time guidance and practical advice to help users navigate uncomfortable or potentially threatening situations.
* **Discreet Fake Call Option:** A strategic feature that allows users to simulate an incoming call, providing a plausible excuse to exit uncomfortable or dangerous encounters.
* **Integrated Video Recording:** Users can discreetly record video evidence directly within the app, securely storing crucial information for later use.
* **Direct Communication Channels:** Facilitates direct calls to local police, official helplines, and personal emergency contacts with a single tap.
* **Intuitive UI/UX Design:** Crafted with **Flutter's declarative UI framework** for seamless navigation, a fluid user experience, and a visually appealing interface, ensuring that critical safety features are readily accessible even under duress.
* **Robust Backend with Supabase:** Leverages **Supabase** for secure and scalable backend operations, ensuring reliable data storage, real-time capabilities, and user authentication.
* **Secure User Authentication:** Implements comprehensive sign-in features with **email verification**, safeguarding user data and ensuring privacy.
* **Customizable Emergency Messaging:** Users have the flexibility to personalize their emergency messages to provide specific context to their contacts.
* **True Cross-Platform Compatibility:** Developed with **Flutter for native compilation on both iOS and Android** platforms, ensuring broad accessibility and consistent performance.
* **Smartwatch Integration:** Designed for future integration with smartwatches, providing enhanced convenience and even quicker access to safety features.

---

## Technologies Used

* **Frontend:** **Flutter** (Dart)
* **Backend:** Supabase (PostgreSQL, Authentication, Realtime, Storage)
* **AI Integration:** Gemini AI
* **Mapping/Location Services:** [Specify your mapping API, e.g., Google Maps API for Flutter, Mapbox, etc.]
* **SMS Gateway:** [If applicable, mention any SMS service you use]

---

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

* **Flutter SDK** installed and configured
* A Supabase project instance
* Gemini API key

### Installation

1.  Clone the repository:
    ```bash
    git clone [https://github.com/your-username/Sakhi-Suraksha.git](https://github.com/your-username/Sakhi-Suraksha.git)
    ```
2.  Navigate to the project directory:
    ```bash
    cd Sakhi-Suraksha
    ```
3.  Install Flutter dependencies:
    ```bash
    flutter pub get
    ```
4.  Configure environment variables:
    Create a `.env` file in the root directory and add your Supabase project URL, Anon Key, and Gemini API key:
    ```
    SUPABASE_URL=YOUR_SUPABASE_URL
    SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY
    ```
5.  Run the application:
    ```bash
    flutter run
    ```

---

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## Contact

Your Name - [Your Email/LinkedIn Profile]

Project Link: [https://github.com/your-username/Sakhi-Suraksha](https://github.com/your-username/Sakhi-Suraksha)
