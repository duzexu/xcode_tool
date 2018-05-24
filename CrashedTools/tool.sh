# Mac 环境下
# 从xcode，iTools，jenkins下载crash log（.crash 后缀）
# 从jenkins下载 BJTime_AdHoc.app BJTime_AdHoc.dSYM 文件
# 将x.crash *.app *.dSYM 文件与symbolicatecrash 至于一个文件夹下
# 运行以下命令 ，crash.log 为最终输出log文件

export DEVELOPER_DIR="/Applications/XCode.app/Contents/Developer"

./symbolicatecrash *.crash ./*.framework.dSYM > crash.log

