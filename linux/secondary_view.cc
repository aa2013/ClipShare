#include <flutter_linux/flutter_linux.h>

// Older Flutter engines do not expose the Impeller toggle.
extern "C" void fl_dart_project_set_enable_impeller(FlDartProject*, gboolean)
    __attribute__((weak));
extern "C" FlView* __real_fl_view_new(FlDartProject*);
extern "C" FlView* __wrap_fl_view_new(FlDartProject* project) {
  if (fl_dart_project_set_enable_impeller != nullptr &&
      g_getenv("FLUTTER_LINUX_RENDERER") == nullptr) {
    fl_dart_project_set_enable_impeller(project, FALSE);
    g_setenv("FLUTTER_LINUX_RENDERER", "software", TRUE);
    FlView* view = __real_fl_view_new(project);
    g_unsetenv("FLUTTER_LINUX_RENDERER");
    return view;
  }
  return __real_fl_view_new(project);
}
