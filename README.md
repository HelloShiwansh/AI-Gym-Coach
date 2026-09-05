# AI Gym Coach

AI Gym Coach is a Streamlit application that uses a webcam, MediaPipe pose landmarks, and exercise-specific form rules to count repetitions in real time. An optional Groq and gTTS coaching pipeline turns workout events and detected form issues into short spoken cues.

The repository also contains a standalone static landing page for presenting the project.

## Features

- Real-time webcam pose detection through `streamlit-webrtc`
- Skeleton overlay and live exercise metrics
- Rep and set tracking using pose landmarks and angle thresholds
- Form checks for depth, alignment, balance, shoulder stability, torso swing, and back arch
- Optional AI voice coaching for workout start, set completion, form issues, and workout completion
- Username-based sessions with local SQLite workout history
- Five supported exercises:
	- Squats
	- Push-ups
	- Biceps Curls (Dumbbell)
	- Shoulder Press
	- Lunges

This is a rule-based pose tracking system, not a trained exercise-classification model. It selects the more visible arm or leg for most exercises; lunges use the knee with the smaller angle as the front leg.

## How It Works

1. The user enters a non-empty username. Usernames are created or reused in SQLite; there is no password or account verification.
2. The user selects an exercise, number of sets, and repetitions per set in the sidebar.
3. Starting a workout opens a browser webcam through WebRTC. Audio capture is disabled.
4. MediaPipe Pose Landmarker processes the mirrored video frames. A detector tracks an exercise stage, then increments reps when the configured down/up movement is completed.
5. Metrics are copied into Streamlit session state and displayed in the sidebar.
6. Each completed set is saved to the local database. History is grouped by exercise and calendar date.

When the camera cannot find a sufficiently visible pose, the video displays `NO POSE DETECTED` and `PLEASE FACE THE CAMERA`.

## Requirements

- Python 3.11 is the project target.
- A webcam and a browser that can grant camera permission are required for workouts.
- Internet access is required for Groq coaching and Google Text-to-Speech.
- Linux deployments may need the system packages listed in `Main App/packages.txt`.

## Local Setup

From PowerShell, run Streamlit with `Main App` as the working directory. The application resolves `static/style.css`, `static/AdobeClean.otf`, and `ml_models/pose_landmarker_full.task` relative to the current working directory.

```powershell
cd "Main App"
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
streamlit run main.py
```

Open the URL printed by Streamlit, usually `http://localhost:8501`, and allow camera access when prompted.

For `uv`, the equivalent setup is:

```powershell
cd "Main App"
uv venv
.venv\Scripts\Activate.ps1
uv pip install -r requirements.txt
uv run streamlit run main.py
```

## Groq Voice Coaching

Voice coaching is optional. Set `GROQ_API_KEY` in the process environment or provide it through Streamlit secrets. The application uses the Groq model `llama-3.3-70b-versatile` and generates English audio with gTTS.

PowerShell example:

```powershell
$env:GROQ_API_KEY = "your_groq_api_key"
streamlit run main.py
```

For Streamlit Cloud, add `GROQ_API_KEY` under the app's secrets configuration. A `.env` file is not loaded automatically by the current code, even though `python-dotenv` is included in `requirements.txt`.

If coaching initialization fails, the workout UI continues without voice coaching. Later network or text-to-speech failures may still interrupt an active coaching request.

## Detector Metrics

| Exercise | Rep signal | Form metrics |
| --- | --- | --- |
| Squats | Knee angle below 100 degrees, then at least 160 degrees | Knee angle, back angle, depth status |
| Push-ups | Elbow angle below 90 degrees, then above 160 degrees | Elbow angle, body alignment, hip position |
| Biceps Curls (Dumbbell) | Elbow angle below 50 degrees, then above 160 degrees | Elbow angle, shoulder stability, torso swing |
| Shoulder Press | Elbow angle above 160 degrees, then below 90 degrees | Elbow angle, arm extension, back arch |
| Lunges | Front knee angle below 100 degrees, then above 160 degrees | Front knee angle, torso angle, balance |

Landmarks must generally have visibility above `0.7` before they can drive rep counting. The detector thresholds are heuristics and can be affected by camera angle, lighting, occlusion, loose clothing, and incomplete body visibility.

## Workout History

The application creates `Main App/data.db` on first run. It contains:

- `users`: username and creation timestamp
- `exercises`: user, exercise name, reps, sets, elapsed time, and creation timestamp

When a set is completed, its reps, set count, and elapsed time are saved. Records for the same user, exercise, and calendar date are merged. Incomplete sets and repetitions from a workout ended early are not saved.

The database is local to the running deployment and is ignored by Git. It is not a shared production database.

## Repository Layout

```text
.
├── LandingPage/                 # Standalone promotional HTML/CSS page
├── Main App/
│   ├── main.py                  # Streamlit entrypoint
│   ├── requirements.txt         # Python dependencies
│   ├── packages.txt             # Linux system packages for deployment
│   ├── core/base_exercise.py    # Shared angle and detector interface
│   ├── detectors/               # Exercise-specific rep/form detectors
│   ├── ml_models/               # MediaPipe pose landmarker model
│   ├── services/
│   │   ├── auth/                # Username session gate
│   │   ├── coaching/            # Groq feedback and gTTS audio
│   │   ├── config/              # Exercise options and prompts
│   │   ├── persistence/          # SQLite repository
│   │   ├── state/                # Streamlit session defaults
│   │   ├── tracking/             # Metrics synchronization and saving
│   │   ├── ui/                  # CSS and font loading
│   │   └── vision/              # WebRTC frame processor
│   ├── static/                  # App stylesheet and local font
│   └── tutorial-info/            # Historical deployment notes
└── README.md
```

## Landing Page

The page at `LandingPage/index.html` can be opened directly in a browser; it has no build step or backend. Its **Try it live** link points to the deployed Streamlit app.

The gallery and demo video are placeholders in the repository. Add the referenced files under `LandingPage/IMGs/` and `LandingPage/videos/`, or update the paths in `index.html`, before publishing the page with complete media.

## Deployment

The Streamlit app can be deployed to Streamlit Cloud using `Main App` as the application directory and `main.py` as the entrypoint. Include the Python dependencies from `requirements.txt`, the Linux packages from `packages.txt`, and the `GROQ_API_KEY` secret if voice coaching is needed.

Because the database is a local SQLite file and the app depends on a live browser camera, deployment should be treated as a personal/demo application. Persistent shared history and production authentication would require additional infrastructure.

## Development Notes

- There are currently no automated test files in the repository.
- The pose model is loaded from `Main App/ml_models/pose_landmarker_full.task` at startup.
- WebRTC uses Google's public STUN server for connection negotiation.
- The app refreshes Streamlit while the video stream is playing so the sidebar can display updated metrics.