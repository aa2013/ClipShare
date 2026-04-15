# Project-level configuration.
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "clipshare")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "top.coclyun.clipshare")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)

  # 豁免第三方插件编译警告：tray_manager 的 deprecated API、hotkey_manager_linux 的未初始化变量
  target_compile_options(${TARGET} PRIVATE
    -Wno-error=deprecated-declarations
    -Wno-error=sometimes-uninitialized
  )

  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Define the application target. To change its name, change BINARY_NAME above,
# not the value here, or `flutter run` will no longer work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})
set_property(TARGET ${BINARY_NAME} APPEND_STRING PROPERTY LINK_FLAGS " -Wl,--disable-new-dtags")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  # Flutter copies plugin build outputs into the bundle as files, so their
  # build-time RUNPATH is preserved. Make the copied plugins resolve sibling
  # libraries from bundle/lib instead of the ephemeral build directory.
  set_target_properties(${plugin}_plugin PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
    BUILD_WITH_INSTALL_RPATH TRUE
  )
  set_property(TARGET ${plugin}_plugin APPEND_STRING PROPERTY LINK_FLAGS " -Wl,--disable-new-dtags")
endforeach(plugin)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Extra runtime libraries used by Linux plugins that are not available on many
# clean desktop installs. Copy them with their sonames so the bundle's RPATH can
# resolve them from lib/ without requiring development packages on the target.
find_library(KEYBINDER_LIBRARY NAMES libkeybinder-3.0.so.0 keybinder-3.0)
find_library(AYATANA_APPINDICATOR_LIBRARY NAMES libayatana-appindicator3.so.1 ayatana-appindicator3)
find_library(AYATANA_INDICATOR_LIBRARY NAMES libayatana-indicator3.so.7 ayatana-indicator3)
find_library(AYATANA_IDO_LIBRARY NAMES libayatana-ido3-0.4.so.0 ayatana-ido3-0.4)
find_library(DBUSMENU_GLIB_LIBRARY NAMES libdbusmenu-glib.so.4 dbusmenu-glib)
find_library(DBUSMENU_GTK3_LIBRARY NAMES libdbusmenu-gtk3.so.4 dbusmenu-gtk3)
find_library(XTST_LIBRARY NAMES libXtst.so.6 Xtst)
find_library(WAYLAND_CLIENT_LIBRARY NAMES libwayland-client.so.0 wayland-client)

function(INSTALL_EXTRA_RUNTIME_LIBRARY LIBRARY_VAR SONAME)
  if(${LIBRARY_VAR})
    install(CODE "
      file(MAKE_DIRECTORY \"${INSTALL_BUNDLE_LIB_DIR}\")
      execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different \"${${LIBRARY_VAR}}\" \"${INSTALL_BUNDLE_LIB_DIR}/${SONAME}\")
    " COMPONENT Runtime)
  else()
    message(WARNING "Runtime library ${SONAME} was not found; packages may still need the system dependency.")
  endif()
endfunction()

install_extra_runtime_library(KEYBINDER_LIBRARY "libkeybinder-3.0.so.0")
install_extra_runtime_library(AYATANA_APPINDICATOR_LIBRARY "libayatana-appindicator3.so.1")
install_extra_runtime_library(AYATANA_INDICATOR_LIBRARY "libayatana-indicator3.so.7")
install_extra_runtime_library(AYATANA_IDO_LIBRARY "libayatana-ido3-0.4.so.0")
install_extra_runtime_library(DBUSMENU_GLIB_LIBRARY "libdbusmenu-glib.so.4")
install_extra_runtime_library(DBUSMENU_GTK3_LIBRARY "libdbusmenu-gtk3.so.4")
install_extra_runtime_library(XTST_LIBRARY "libXtst.so.6")
install_extra_runtime_library(WAYLAND_CLIENT_LIBRARY "libwayland-client.so.0")

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
