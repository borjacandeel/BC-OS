cmake_minimum_required(VERSION 3.21)
project(bc-shell VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick LinguistTools Test)
qt_standard_project_setup()

qt_add_executable(bc-shell src/main.cpp src/appconfig.h src/appconfig.cpp
    src/launcher.h src/launcher.cpp src/filebrowser.h src/filebrowser.cpp)

set(BC_QML_FILES
    qml/Main.qml qml/Theme.qml qml/Icons.qml qml/Icon.qml qml/Wallpaper.qml
    qml/TopBar.qml qml/Dock.qml qml/AppIcon.qml qml/FilesWindow.qml
    qml/FileGlyph.qml qml/ControlCenter.qml qml/NotificationCard.qml qml/Brand.qml)
foreach(f ${BC_QML_FILES})
    get_filename_component(n ${f} NAME)
    set_source_files_properties(${f} PROPERTIES QT_RESOURCE_ALIAS ${n})
endforeach()
set_source_files_properties(qml/Theme.qml qml/Icons.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(bc-shell
    URI BCShell
    VERSION 1.0
    QML_FILES ${BC_QML_FILES}
    RESOURCES assets/BC-logo-blanco.svg
)

qt_add_translations(bc-shell
    TS_FILES i18n/bcshell_es_ES.ts i18n/bcshell_en.ts
    RESOURCE_PREFIX /i18n
)

target_link_libraries(bc-shell PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
install(TARGETS bc-shell RUNTIME DESTINATION bin)

enable_testing()
set(BC_ENV "QT_QPA_PLATFORM=offscreen" "QT_QUICK_BACKEND=software")
add_test(NAME carga_es COMMAND bc-shell --check --lang es_ES --expect-title "Actualizaciones"
         --screenshot ${CMAKE_BINARY_DIR}/captura-es.png)
add_test(NAME carga_en COMMAND bc-shell --check --lang en --expect-title "Updates"
         --screenshot ${CMAKE_BINARY_DIR}/captura-en.png)
add_test(NAME movimiento_reducido COMMAND bc-shell --check --lang es_ES --reduced-motion
         --expect-title "Actualizaciones")
set_tests_properties(carga_es carga_en movimiento_reducido PROPERTIES ENVIRONMENT "${BC_ENV}")

qt_add_executable(tst_shell tests/tst_shell.cpp src/launcher.h src/launcher.cpp src/filebrowser.h src/filebrowser.cpp)
target_link_libraries(tst_shell PRIVATE Qt6::Core Qt6::Gui Qt6::Test)
add_test(NAME modelo_archivos_y_lanzador COMMAND tst_shell)
set_tests_properties(modelo_archivos_y_lanzador PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
foreach(sz 1280x800 1920x1080 1024x640)
    add_test(NAME responsive_${sz} COMMAND bc-shell --check --lang es_ES --size ${sz}
             --expect-title "Actualizaciones" --screenshot ${CMAKE_BINARY_DIR}/captura-${sz}.png)
    set_tests_properties(responsive_${sz} PROPERTIES ENVIRONMENT "${BC_ENV}")
endforeach()
