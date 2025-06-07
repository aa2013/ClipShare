#include "my_application.h"

int main(int argc, char** argv) {
    MyApplication* ptr = my_application_new();
    if(!ptr){
        return 0;
    }
  g_autoptr(MyApplication) app = ptr;
  return g_application_run(G_APPLICATION(app), argc, argv);
}
