#include "my_application.h"
#include <unistd.h>
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "window_manager/window_manager_plugin.h"
#include "desktop_drop/desktop_drop_plugin.h"

const char* PID_FILE_NAME = "pid.txt";
struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};
GtkWindow *main_window;
G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

void write_pid_to_file(const char *filename) {
    pid_t pid = getpid();
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("can not open file!");
        return;
    }
    // 写入PID
    fprintf(file, "%d", pid);
    fclose(file);
}

pid_t read_pid_from_file(const char *filename) {
    // 读取PID
    int pid = 0;
    // 打开文件
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("can not open file");
        return (pid_t)pid;
    }

    if (fscanf(file, "%d", &pid) != 1) {
        fclose(file);
        return (pid_t)pid;
    }
    fclose(file);
    return (pid_t)pid;
}

void send_signal_to_pid(pid_t target_pid) {
    if (kill(target_pid, SIGUSR1) == -1) {
        g_print("Failed to send signal");
    }
}

char* get_process_name_by_pid(pid_t pid) {
    static char proc_name[256];
    char path[64];
    FILE* fp;
    snprintf(path, sizeof(path), "/proc/%d/comm", pid);
    fp = fopen(path, "r");
    if (!fp) {
        g_print("%s", "Failed to open /proc/[PID]/comm");
        return nullptr;
    }

    if (fgets(proc_name, sizeof(proc_name), fp) == NULL) {
        fclose(fp);
        return nullptr;
    }
    fclose(fp);
    proc_name[strcspn(proc_name, "\n")] = '\0';
    return proc_name;
}

static void init_desktop_multi_window_plugin_window_created(FlPluginRegistry* registry) {
    g_autoptr(FlPluginRegistrar) window_manager_registrar = fl_plugin_registry_get_registrar_for_plugin(registry, "WindowManagerPlugin");
    window_manager_plugin_register_with_registrar(window_manager_registrar);
    g_autoptr(FlPluginRegistrar) desktop_drop_registrar = fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopDropPlugin");
    desktop_drop_plugin_register_with_registrar(desktop_drop_registrar);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  main_window = window;
  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "ClipShare");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "ClipShare");
  }
  gtk_window_set_default_size(window, 1000, 650);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  desktop_multi_window_plugin_set_window_created_callback(init_desktop_multi_window_plugin_window_created);
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);
  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  main_window = nullptr;
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

static void handle_sigusr1(int sig) {
    if (main_window) {
        gtk_window_present(main_window);
    }
}
MyApplication* my_application_new() {
  pid_t pid = read_pid_from_file(PID_FILE_NAME);
  char* my_process_name = get_process_name_by_pid(getpid());
  if(pid){
      char* process_name = get_process_name_by_pid(pid);
      if(process_name){
          //already exists instance
          if(strcmp(process_name, my_process_name) == 0){
              send_signal_to_pid(pid);
              return nullptr;
          }
      }
  }
  signal(SIGUSR1, handle_sigusr1);
  write_pid_to_file(PID_FILE_NAME);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
