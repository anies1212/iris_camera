#include "include/ios_camera_lens_switcher/ios_camera_lens_switcher_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ios_camera_lens_switcher_plugin.h"

void IosCameraLensSwitcherPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ios_camera_lens_switcher::IosCameraLensSwitcherPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
