#! /bin/bash
mv ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins.backup

# rm ~/Library/Developer/Xcode/UserData/CodeSnippets

SRC_HOME=`pwd`
ln -s ${SRC_HOME}/Plug-ins ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins
echo "done"

