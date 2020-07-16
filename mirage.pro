# Custom functions

defineReplace(glob_filenames) {
    for(pattern, ARGS) {
        results *= $$files(src/$${pattern}, true)
    }
    return($$results)
}


# Base configuration

# widgets: Make native file dialogs available to QML (must use QApplication)
QT        = quick quickcontrols2 widgets
DEFINES  += QT_DEPRECATED_WARNINGS
CONFIG   += warn_off c++11 release
TEMPLATE  = app

BUILD_DIR   = build
MOC_DIR     = $$BUILD_DIR/moc
OBJECTS_DIR = $$BUILD_DIR/obj
RCC_DIR     = $$BUILD_DIR/rcc

QRC_FILE = $$BUILD_DIR/resources.qrc

RESOURCES += $$QRC_FILE
HEADERS   += $$glob_filenames(*.h) submodules/hsluv-c/src/hsluv.h
SOURCES   += $$glob_filenames(*.cpp) submodules/hsluv-c/src/hsluv.c
TARGET     = mirage

unix:!macx {
    LIBS += -lX11 -lXss
}


# Custom CONFIG options

dev {
    # Enable debugging and don't use the Qt Resource System to compile faster
    CONFIG    -= warn_off release
    CONFIG    += debug qml_debug declarative_debug
    RESOURCES -= $$QRC_FILE

    warning(make install cannot be used with the dev CONFIG option.)
}

no-x11 {
    # Compile without X11-specific features (auto-away)
    DEFINES += NO_X11
    LIBS    -= -lX11 -lXss
}


# Files to copy for `make install`

!dev:unix {
    isEmpty(PREFIX) { PREFIX = /usr/local }

    executables.path  = $$PREFIX/bin
    executables.files = $$TARGET

    shortcuts.path  = $$PREFIX/share/applications
    shortcuts.files = extra/linux/mirage.desktop

    icons256.path = $$PREFIX/share/icons/hicolor/256x256/apps
    icons256.files = extra/linux/mirage.png
    INSTALLS += icons256

    INSTALLS += executables shortcuts icons256
}

!dev:win32 {
    executables.path  = "C:/Program Files"
    executables.files = $$TARGET

    INSTALLS += executables
}


# Generate resource file

RESOURCE_FILES *= $$glob_filenames(qmldir, *.qml, *.qpl, *.js, *.py)
RESOURCE_FILES *= $$glob_filenames( *.jpg, *.jpeg, *.png, *.svg)

file_content += '<!-- vim: set ft=xml : -->'
file_content += '<!DOCTYPE RCC>'
file_content += '<RCC version="1.0">'
file_content += '<qresource prefix="/">'

for(file, RESOURCE_FILES) {
    file_content += '    <file alias="$$file">../$$file</file>'
}

file_content += '</qresource>'
file_content += '</RCC>'

write_file($$QRC_FILE, file_content)


# Add stuff to `make clean`

# Allow cleaning folders instead of just files
win32:QMAKE_DEL_FILE = rmdir /q /s
!win32:QMAKE_DEL_FILE = rm -rf

for(file, $$list($$glob_filenames(*.py))) {
    PYCACHE_DIRS *= $$dirname(file)/__pycache__
    PYCACHE_DIRS *= $$dirname(file)/.mypy_cache
}

QMAKE_CLEAN *= $$MOC_DIR $$OBJECTS_DIR $$RCC_DIR $$PYCACHE_DIRS $$QRC_FILE
QMAKE_CLEAN *= $$BUILD_DIR $$TARGET Makefile mirage.pro.user .qmake.stash
QMAKE_CLEAN *= $$glob_filenames(*.pyc, *.qmlc, *.jsc, *.egg-info)
QMAKE_CLEAN *= packaging/flatpak/flatpak-env packaging/flatpak/requirements.txt
QMAKE_CLEAN *= packaging/flatpak/flatpak-requirements.txt
QMAKE_CLEAN *= packaging/flatpak/flatpak-pip.json .flatpak-builder
