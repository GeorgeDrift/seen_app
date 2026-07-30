package com.seen.seen_app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by the `health`
// plugin on Android 14+: Health Connect permission requests use
// registerForActivityResult, which needs an activity castable to
// ComponentActivity.
class MainActivity : FlutterFragmentActivity()
