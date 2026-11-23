cmake_minimum_required(VERSION 3.21)
project(bc-shell VERSION 0.4.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick Network DBus LinguistTools Test)
find_package(LayerShellQt QUIET)
find_library(PAM_LIBRARY pam REQUIRED)
qt_standard_project_setup()

add_library(bccommon STATIC src/appconfig.h src/appconfig.cpp src/appsettings.h src/appsettings.cpp src/powercontrol.h src/powercontrol.cpp
    src/userlist.h src/userlist.cpp)
target_link_libraries(bccommon PUBLIC Qt6::Core Qt6::Gui)

# BC Adaptive Renderer (lado Qt): backend de Qt Quick, nivel de calidad y medida de fotogramas en cada proceso BC
add_library(bcrender STATIC src/renderengine.h src/renderengine.cpp)
target_link_libraries(bcrender PUBLIC Qt6::Core Qt6::Gui Qt6::Quick Qt6::DBus)

qt_add_executable(bc-shell src/main.cpp src/launcher.h src/launcher.cpp src/filebrowser.h src/filebrowser.cpp
    src/pamauth.h src/pamauth.cpp src/systemstatus.h src/systemstatus.cpp
    src/notifications.h src/notifications.cpp src/sysmonitor.h src/sysmonitor.cpp src/appindex.h src/appindex.cpp src/packagestore.h src/packagestore.cpp
    src/swaycontrol.h src/swaycontrol.cpp src/sessionlist.h src/sessionlist.cpp src/clipboardhistory.h src/clipboardhistory.cpp src/updatechecker.h src/updatechecker.cpp src/layerhelper.h src/layerhelper.cpp src/shellcontrol.h src/shellcontrol.cpp src/glassprovider.h src/glassprovider.cpp src/genieitem.h src/genieitem.cpp src/geniemesh.h src/geniemesh.cpp src/desktopdata.h src/desktopdata.cpp src/installer.h src/installer.cpp)

set(BC_QML_FILES
    qml/Panel.qml qml/Taskbar.qml qml/StartMenu.qml qml/Widgets.qml qml/Welcome.qml qml/SlideIn.qml qml/WindowChrome.qml qml/Osd.qml qml/ClipboardPopup.qml qml/LayerWindow.qml qml/UiState.qml qml/AppMenus.qml qml/MenuPopup.qml qml/OverlayScroll.qml qml/ForceQuit.qml qml/EmojiPicker.qml qml/Lazy.qml qml/ScreenshotPanel.qml qml/FilesApp.qml
    qml/Theme.qml qml/Icons.qml qml/IconCache.qml qml/Icon.qml qml/Wallpaper.qml
    qml/TopBar.qml qml/Dock.qml qml/AppIcon.qml
    qml/FileGlyph.qml qml/ControlCenter.qml qml/NotificationCard.qml qml/Brand.qml
    qml/LoginPanel.qml qml/PowerButton.qml qml/PowerDialog.qml qml/BigClock.qml qml/LockScreen.qml
    qml/Splash.qml qml/AppWindow.qml qml/MonitorApp.qml qml/SettingsApp.qml qml/LauncherPanel.qml qml/StoreApp.qml
    qml/Glass.qml qml/MenuBar.qml qml/DesktopWidgets.qml qml/DockGG.qml qml/ControlCenterGG.qml
    qml/NotificationCenter.qml qml/Spotlight.qml qml/Launchpad.qml qml/Genie.qml qml/MissionControl.qml qml/AppSwitcher.qml qml/DesktopIcons.qml qml/CalculatorApp.qml qml/NotesApp.qml qml/PreviewApp.qml qml/RemindersApp.qml qml/CalendarApp.qml qml/SidebarGlass.qml qml/MusicApp.qml qml/InstallerApp.qml)
set(BC_GREETER_QML qml/Greeter.qml qml/LoginPanel.qml qml/PowerButton.qml qml/PowerDialog.qml qml/BigClock.qml
    qml/Theme.qml qml/Icons.qml qml/IconCache.qml qml/Icon.qml qml/Wallpaper.qml qml/Brand.qml qml/UiState.qml qml/AppMenus.qml)
foreach(f ${BC_QML_FILES} qml/Greeter.qml)
    get_filename_component(n ${f} NAME)
    set_source_files_properties(${f} PROPERTIES QT_RESOURCE_ALIAS ${n})
endforeach()
set_source_files_properties(qml/Theme.qml qml/Icons.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/IconCache.qml qml/UiState.qml qml/AppMenus.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(bc-shell
    URI BCShell
    VERSION 1.0
    QML_FILES ${BC_QML_FILES}
    RESOURCES assets/BC-logo-blanco.svg assets/BC-logo-oscuro.svg assets/wallpaper-default.png assets/wallpaper-login.png assets/window-shadow.png
)

qt_add_translations(bc-shell
    TS_FILES i18n/bcshell_es_ES.ts i18n/bcshell_en.ts
    RESOURCE_PREFIX /i18n
)

file(GLOB BC_APPICON_FILES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/assets/apps/*.svg)
file(GLOB BC_ICON_FILES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/*.svg)
qt_add_resources(bc-shell bcicons PREFIX /BCShell/icons BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons FILES ${BC_ICON_FILES})
qt_add_resources(bc-shell bcappicons PREFIX /BCShell/apps BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/apps FILES ${BC_APPICON_FILES})

target_link_libraries(bc-shell PRIVATE bccommon bcrender Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::DBus Qt6::Network ${PAM_LIBRARY})
if(LayerShellQt_FOUND)
    target_link_libraries(bc-shell PRIVATE LayerShellQt::Interface)
    target_compile_definitions(bc-shell PRIVATE BC_HAVE_LAYERSHELL)
    message(STATUS "layer-shell-qt: sí")
else()
    message(WARNING "layer-shell-qt no encontrado: el panel no podrá usar wlr-layer-shell")
endif()

# Greeter para greetd
qt_add_executable(bc-greeter src/greeter_main.cpp src/greetd.h src/greetd.cpp src/sessionlist.h src/sessionlist.cpp)
qt_add_qml_module(bc-greeter
    URI BCShell
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/greeter_qml/BCShell
    QML_FILES ${BC_GREETER_QML}
    RESOURCES assets/BC-logo-blanco.svg assets/wallpaper-default.png assets/wallpaper-login.png
)
qt_add_translations(bc-greeter
    TS_FILES i18n/bcshell_es_ES.ts i18n/bcshell_en.ts
    RESOURCE_PREFIX /i18n
)
qt_add_resources(bc-greeter bcicons_g PREFIX /BCShell/icons BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons FILES ${BC_ICON_FILES})
target_link_libraries(bc-greeter PRIVATE bccommon bcrender Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network)
install(TARGETS bc-shell bc-greeter RUNTIME DESTINATION bin)

# Terminal de BC (como el Terminal de macOS): solo si está QTermWidget (paquete «qtermwidget»)
find_package(qtermwidget6 QUIET)
if(qtermwidget6_FOUND)
    find_package(Qt6 REQUIRED COMPONENTS Widgets)
    add_executable(bc-terminal-app terminal/main.cpp)
    target_link_libraries(bc-terminal-app PRIVATE Qt6::Widgets qtermwidget6)
    install(TARGETS bc-terminal-app RUNTIME DESTINATION lib/bc)
    install(FILES terminal/BC-Oscuro.colorscheme terminal/BC-Claro.colorscheme DESTINATION share/bc/terminal)
else()
    message(WARNING "qtermwidget6 no encontrado: no se compila la Terminal de BC (se usará Ghostty/Alacritty/foot)")
endif()

enable_testing()
set(BC_ENV "QT_QPA_PLATFORM=offscreen" "QT_QUICK_BACKEND=software")
add_test(NAME carga_es COMMAND bc-shell --check --lang es_ES --expect-title "Actualizaciones"
         --screenshot ${CMAKE_BINARY_DIR}/captura-es.png)
add_test(NAME carga_en COMMAND bc-shell --check --lang en --expect-title "Updates"
         --screenshot ${CMAKE_BINARY_DIR}/captura-en.png)
add_test(NAME movimiento_reducido COMMAND bc-shell --check --lang es_ES --reduced-motion
         --expect-title "Actualizaciones")
set_tests_properties(carga_es carga_en movimiento_reducido PROPERTIES ENVIRONMENT "${BC_ENV}")

qt_add_executable(tst_shell tests/tst_shell.cpp src/installer.h src/installer.cpp src/sessionlist.h src/sessionlist.cpp src/sysmonitor.h src/sysmonitor.cpp src/clipboardhistory.h src/clipboardhistory.cpp src/updatechecker.h src/updatechecker.cpp src/launcher.h src/launcher.cpp src/filebrowser.h src/filebrowser.cpp
    src/systemstatus.h src/systemstatus.cpp src/appindex.h src/appindex.cpp src/packagestore.h src/packagestore.cpp src/swaycontrol.h src/swaycontrol.cpp src/userlist.h src/userlist.cpp src/greetd.h src/greetd.cpp src/powercontrol.h src/powercontrol.cpp)
target_link_libraries(tst_shell PRIVATE Qt6::Core Qt6::Gui Qt6::Network Qt6::Test)
add_test(NAME modelo_archivos_y_lanzador COMMAND tst_shell)
set_tests_properties(modelo_archivos_y_lanzador PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
add_test(NAME greeter_login_ok COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tests/greeter_protocol.sh
         $<TARGET_FILE:bc-greeter> ${CMAKE_CURRENT_SOURCE_DIR}/tests/fake_greetd.py bc:bcos 0)
add_test(NAME greeter_login_clave_mala COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tests/greeter_protocol.sh
         $<TARGET_FILE:bc-greeter> ${CMAKE_CURRENT_SOURCE_DIR}/tests/fake_greetd.py bc:mala 10)
add_test(NAME greeter_captura COMMAND bc-greeter --check --size 1280x800 --lang es_ES
         --screenshot ${CMAKE_BINARY_DIR}/captura-greeter.png)
set_tests_properties(greeter_captura PROPERTIES ENVIRONMENT "${BC_ENV}")
qt_add_executable(tst_render tests/tst_render.cpp)
target_link_libraries(tst_render PRIVATE bcrender Qt6::Test)
add_test(NAME motor_render COMMAND tst_render)
qt_add_executable(tst_notif tests/tst_notif.cpp src/notifications.h src/notifications.cpp)
target_link_libraries(tst_notif PRIVATE Qt6::Core Qt6::Gui Qt6::DBus Qt6::Test)
find_program(BC_DBUS_RUN_SESSION dbus-run-session)
if(BC_DBUS_RUN_SESSION)
    add_test(NAME notificaciones_dbus COMMAND ${BC_DBUS_RUN_SESSION} -- $<TARGET_FILE:tst_notif>)
else()
    add_test(NAME notificaciones_dbus COMMAND tst_notif)
endif()
set_tests_properties(notificaciones_dbus PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
foreach(sz 1280x800 1920x1080 1024x640)
    add_test(NAME responsive_${sz} COMMAND bc-shell --check --lang es_ES --size ${sz}
             --expect-title "Actualizaciones" --screenshot ${CMAKE_BINARY_DIR}/captura-${sz}.png)
    set_tests_properties(responsive_${sz} PROPERTIES ENVIRONMENT "${BC_ENV}")
endforeach()
