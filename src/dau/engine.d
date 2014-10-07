module dau.engine;

// library setup
pragma(lib, "dallegro5");
version(none)
{

}
else
{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
	pragma(lib, "allegro_audio");
	pragma(lib, "allegro_acodec");
}

// make all allegro functions available
public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;
public import allegro5.allegro_audio;
public import allegro5.allegro_acodec;

alias InitFunction = void function();
alias ShutdownFunction = void function();

// global variables
ALLEGRO_DISPLAY* mainDisplay;
ALLEGRO_EVENT_QUEUE* mainEventQueue;
ALLEGRO_TIMER* mainTimer;

/// global settings
enum Settings {
  fps     = 60,   /// frames-per-second of update/draw loop
  screenW = 800,  /// screen width
  screenH = 600,  /// screen height
  numAudioSamples = 4,  /// number of audio samples to reserve
}

/// paths to configuration files and content
enum Paths {
  bitmapDir           = "./content/image",
  textureData         = "./data/textures.json",
  fontData            = "content/fonts.cfg",
  mapDir              = "content/maps",
  soundData           = "content/sounds.cfg",
  musicData           = "content/music.cfg",
}

// allegro initialization
void startGame() {
  al_init();

  mainDisplay = al_create_display(Settings.screenW, Settings.screenH);
  mainEventQueue = al_create_event_queue();
  mainTimer = al_create_timer(1.0 / Settings.fps);

  al_install_keyboard();
  al_install_mouse();
  al_install_joystick();
  al_install_audio();
  al_init_acodec_addon();
  al_init_image_addon();
  al_init_font_addon();
  al_init_ttf_addon();
  al_init_primitives_addon();

  al_reserve_samples(Settings.numAudioSamples);

  al_register_event_source(mainEventQueue, al_get_display_event_source(mainDisplay));
  al_register_event_source(mainEventQueue, al_get_keyboard_event_source());
  al_register_event_source(mainEventQueue, al_get_mouse_event_source());
  al_register_event_source(mainEventQueue, al_get_timer_event_source(mainTimer));
  al_register_event_source(mainEventQueue, al_get_joystick_event_source());

  with(ALLEGRO_BLEND_MODE)
  {
    al_set_blender(ALLEGRO_BLEND_OPERATIONS.ALLEGRO_ADD, ALLEGRO_ALPHA, ALLEGRO_INVERSE_ALPHA);
  }

  foreach(fn ; _initializers) {
    fn();
  }

  al_start_timer(mainTimer); // start fps timer
}

void shutdownGame() {
  foreach(fn ; _deInitializers) {
    fn();
  }
}

void onInit(InitFunction fn) {
  _initializers ~= fn;
}

void onShutdown(ShutdownFunction fn) {
  _deInitializers ~= fn;
}

private:
InitFunction[] _initializers;
ShutdownFunction[] _deInitializers;