
#include "kobofrotzwindow.h"
#include "version.h"
#include <QApplication>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

// Helper function to create full version string with 4-digit hex build number
QString getFullVersionString() {
    return QString("%1-%2").arg(KOBOFROTZ_VERSION_STRING)
                           .arg(KOBOFROTZ_BUILD_NUMBER, 4, 16, QChar('0')).toUpper();
}

QString getAppTitle() {
    return QString("%1 %2").arg(KOBOFROTZ_APP_NAME).arg(getFullVersionString());
}

int main(int argc, char* argv[] ){
    QApplication a(argc,argv);
    
    // Set application metadata
    a.setApplicationName(KOBOFROTZ_APP_NAME);
    a.setApplicationVersion(getFullVersionString());

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
    w.setWindowTitle(getAppTitle());
    w.showFullScreen();
    return a.exec();
}
