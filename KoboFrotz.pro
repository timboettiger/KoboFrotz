#-------------------------------------------------
#
# Project created by QtCreator 2013-12-09T07:39:37
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = KoboFrotz
TEMPLATE = app

# Auto-increment build number before compilation
unix {
    PRE_TARGETDEPS += increment_build
    increment_build.commands = $$PWD/increment-build.sh $$PWD/version.h
    increment_build.target = increment_build
    QMAKE_EXTRA_TARGETS += increment_build
}

SOURCES += \
    qttext.cpp \
    qtscreen.cpp \
    qtpic.cpp \
    qtinput.cpp \
    qtinit.cpp \
    qtfile.cpp \
    qtaudio.cpp \
    frotz/variable.c \
    frotz/text.c \
    frotz/table.c \
    frotz/stream.c \
    frotz/sound.c \
    frotz/screen.c \
    frotz/redirect.c \
    frotz/random.c \
    frotz/quetzal.c \
    frotz/process.c \
    frotz/object.c \
    frotz/math.c \
    frotz/frotz_main.c \
    frotz/input.c \
    frotz/hotkey.c \
    frotz/files.c \
    frotz/fastmem.c \
    frotz/err.c \
    frotz/buffer.c \
    main.cpp \
    kobofrotzview.cpp \
    kobofrotzwindow.cpp

HEADERS  += \
    frotz/setup.h \
    frotz/frotz.h \
    kobofrotz.h \
    kobofrotzview.h \
    kobofrotzwindow.h \
    version.h

FORMS    += \
    kobofrotzwindow.ui

include(QScreenKeyboard/QScreenKeyboard.pri)
include(KoFileDialog/KoFileDialog.pri)
include(KoSettingsDialog/KoSettingsDialog.pri)
