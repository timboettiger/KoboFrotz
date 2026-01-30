
#include "kobofrotzwindow.h"
#include "version.h"
#include <QApplication>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

int main(int argc, char* argv[] ){
    QApplication a(argc,argv);
    
    // Set application metadata
    a.setApplicationName(KOBOFROTZ_APP_NAME);
    a.setApplicationVersion(KOBOFROTZ_FULL_VERSION);

    // Try multiple stylesheet locations for flexibility
    QStringList stylesheetPaths = {
        "/etc/eink.qss",                                    // Kobo system default
        QDir::homePath() + "/.config/kobofrotz/eink.qss",  // User config
        QApplication::applicationDirPath() + "/eink.qss",   // App directory
        ":/styles/eink.qss"                                 // Embedded resource
    };

    for (const QString& path : stylesheetPaths) {
        QFile stylesheetFile(path);
        if (stylesheetFile.exists() && stylesheetFile.open(QFile::ReadOnly)) {
            a.setStyleSheet(stylesheetFile.readAll());
            stylesheetFile.close();
            break;
        }
    }

    KoboFrotzWindow w;
    w.setWindowTitle(KOBOFROTZ_APP_TITLE);
    w.showFullScreen();
    return a.exec();
}
