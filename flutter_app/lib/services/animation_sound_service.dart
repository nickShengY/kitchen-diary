/// Service for managing sound effects in the animation system.
/// 
/// This is a placeholder service that defines the interface for sound playback.
/// Actual implementation would require adding an audio package like audioplayers.
class AnimationSoundService {
  static final AnimationSoundService _instance = AnimationSoundService._internal();
  factory AnimationSoundService() => _instance;
  AnimationSoundService._internal();

  bool _enabled = true;
  double _volume = 0.8;

  /// Sound effect IDs mapped to action types
  static const Map<String, String> soundEffects = {
    'chop_sound': 'assets/sounds/chop.mp3',
    'peel_sound': 'assets/sounds/peel.mp3',
    'grate_sound': 'assets/sounds/grate.mp3',
    'mix_sound': 'assets/sounds/mix.mp3',
    'whisk_sound': 'assets/sounds/whisk.mp3',
    'splash_sound': 'assets/sounds/splash.mp3',
    'sizzle_sound': 'assets/sounds/sizzle.mp3',
    'pan_toss_sound': 'assets/sounds/pan_toss.mp3',
    'boiling_sound': 'assets/sounds/boiling.mp3',
    'steam_sound': 'assets/sounds/steam.mp3',
    'oven_hum': 'assets/sounds/oven_hum.mp3',
    'fire_crackle': 'assets/sounds/fire_crackle.mp3',
    'blender_sound': 'assets/sounds/blender.mp3',
    'plate_sound': 'assets/sounds/plate.mp3',
    'sprinkle_sound': 'assets/sounds/sprinkle.mp3',
    'drizzle_sound': 'assets/sounds/drizzle.mp3',
    'success_sound': 'assets/sounds/success.mp3',
    'step_complete': 'assets/sounds/step_complete.mp3',
  };

  /// Enable or disable sound effects
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if sound effects are enabled
  bool get isEnabled => _enabled;

  /// Set the volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Get the current volume
  double get volume => _volume;

  /// Play a sound effect by ID
  /// 
  /// In a real implementation, this would load and play the audio file.
  /// For now, this is a stub that logs the sound that would be played.
  Future<void> play(String soundId, {double? atTime}) async {
    if (!_enabled) return;

    final soundPath = soundEffects[soundId];
    if (soundPath == null) {
      // Sound not found, silently ignore
      return;
    }

    // TODO: Implement actual audio playback
    // Example with audioplayers package:
    // final player = AudioPlayer();
    // await player.play(AssetSource(soundPath.replaceFirst('assets/', '')));
    // await player.setVolume(_volume);
    
    // For now, just log
    // ignore: avoid_print
    print('[Sound] Playing $soundId at volume $_volume${atTime != null ? " starting at $atTime" : ""}');
  }

  /// Play sound for an action based on its timing configuration
  Future<void> playForAction(Map<String, dynamic> actionData, {
    required double animationProgress,
  }) async {
    if (!_enabled) return;

    final soundId = actionData['soundId'] as String?;
    if (soundId == null) return;

    final soundTiming = actionData['soundTiming'] as Map<String, dynamic>?;
    if (soundTiming == null) {
      // No timing info, play immediately
      await play(soundId);
      return;
    }

    // Check if we should play based on timing
    final startTime = soundTiming['start'] as double? ?? 0.0;
    final peakTime = soundTiming['peak'] as double?;
    final endTime = soundTiming['end'] as double? ?? 1.0;
    final sustain = soundTiming['sustain'] as double?;

    // Play at start time
    if (animationProgress >= startTime && animationProgress < startTime + 0.05) {
      await play(soundId);
    }

    // Play at peak time
    if (peakTime != null && animationProgress >= peakTime && animationProgress < peakTime + 0.05) {
      await play(soundId);
    }

    // Handle sustained sounds (would need looping implementation)
    if (sustain != null && sustain > 0 && animationProgress >= startTime && animationProgress <= endTime) {
      // TODO: Implement looping sound for sustained effects
    }
  }

  /// Stop all currently playing sounds
  Future<void> stopAll() async {
    // TODO: Implement stop all sounds
    // ignore: avoid_print
    print('[Sound] Stopping all sounds');
  }

  /// Preload sounds for faster playback
  Future<void> preloadSounds(List<String> soundIds) async {
    // TODO: Implement sound preloading
    for (final soundId in soundIds) {
      if (soundEffects.containsKey(soundId)) {
        // ignore: avoid_print
        print('[Sound] Preloading $soundId');
      }
    }
  }

  /// Play step completion sound
  Future<void> playStepComplete() async {
    await play('step_complete');
  }

  /// Play animation completion sound
  Future<void> playSuccess() async {
    await play('success_sound');
  }
}

/// Extension to easily trigger sounds from action maps
extension SoundActionExtension on Map<String, dynamic> {
  Future<void> playSound({double progress = 0.0}) async {
    await AnimationSoundService().playForAction(this, animationProgress: progress);
  }
}
