#ifndef KOBOFROTZWINDOW_H
#define KOBOFROTZWINDOW_H

#include <QMainWindow>

namespace Ui {
class KoboFrotzWindow;
}

class KoboFrotzWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit KoboFrotzWindow(QWidget *parent = 0);
    ~KoboFrotzWindow();

private slots:
    void on_actionExit_triggered();
    void on_actionSave_triggered();
    void on_actionSaveSlot1_triggered();
    void on_actionSaveSlot2_triggered();
    void on_actionSaveSlot3_triggered();
    void on_actionSaveSlot4_triggered();
    void on_actionSaveSlot5_triggered();
    void on_actionSaveSlot6_triggered();
    void on_actionSaveSlot7_triggered();
    void on_actionSaveSlot8_triggered();
    void on_actionSaveSlot9_triggered();
    void on_actionRestore_triggered();
    void on_actionRestoreSlot1_triggered();
    void on_actionRestoreSlot2_triggered();
    void on_actionRestoreSlot3_triggered();
    void on_actionRestoreSlot4_triggered();
    void on_actionRestoreSlot5_triggered();
    void on_actionRestoreSlot6_triggered();
    void on_actionRestoreSlot7_triggered();
    void on_actionRestoreSlot8_triggered();
    void on_actionRestoreSlot9_triggered();
    void on_actionHelp_triggered();
    void on_actionSettings_triggered();
    void on_frotzView_gameStart();
    void on_frotzView_gameQuit();

private:
    Ui::KoboFrotzWindow *ui;
};

#endif // KOBOFROTZWINDOW_H
