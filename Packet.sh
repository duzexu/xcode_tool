#!/bin/sh

#  Packet.sh
#  
#
#  Created by 杜 泽旭 on 2017/2/10.
#

#Log
function LogError() {
    echo "\033[31m$1\033[0m"
}

function LogInfo() {
    echo "\033[36m$1\033[0m"
}

#编译的configuration，默认为Release
build_config=Release

#打包参数
# -v NAME 版本号
# -c NAME 工程的configuration,默认为Release
param_pattern="c:v:"
while getopts $param_pattern opt
do
    case "$opt" in
      c)
		build_config=$OPTARG
        ;;
      v)
        version=$OPTARG
        ;;
    esac
done

if [ -z "$version" ] ;then
    LogError "请输入版本号"
    exit
fi

#存放打包出来的版本的文件夹
podsDir="/Users/duzexu/Desktop/SDK/pods"
#存放archive文件
archivesDir="/Users/duzexu/Desktop/SDK/archives"
#存放打包出来ipa的文件夹
ipasDir="/Users/duzexu/Desktop/SDK/ipas"
#pod库地址
podDir="/Users/duzexu/Desktop/360iOSLoginSDK/SDK-NEW/QHLoginFramework"
#pod打包地址
podVersionDir="$podDir/QHLoginFramework-$version"
#工程地址
projectDir="/Users/duzexu/Desktop/360iOSLoginSDK_v0.3.0_release"

#创建文件夹
if [ ! -d $podsDir ]; then
mkdir $podsDir
fi

if [ ! -d $archivesDir ]; then
mkdir $archivesDir
fi

if [ ! -d $ipasDir ]; then
mkdir $ipasDir
fi

#提交git
cd $podDir
rm -rf $podVersionDir
git add .
git commit -m v${version}

#打tag
if test $? = 0; then
file="/Users/duzexu/Desktop/SDK/log.txt"
git tag > $file
for tag in `cat $file`
do
if test $tag = $version; then
    LogInfo "存在版本 $tag "
    git tag -d $version
fi
done
git tag $version
else
    LogInfo "没有内容更改"
fi

#pod 打包
cd /Users/duzexu/Library/Caches/CocoaPods/Pods/External/QHLoginFramework
rm -rf  *
cd $podDir
pod package QHLoginFramework.podspec --embedded --force --configuration=$build_config
if test $? = 1; then
    LogError "pod 打包失败"
    exit
fi

#备份打包文件到版本库
resultDir="$podVersionDir/ios/QHLoginFramework.embeddedframework"
date=`date +%m-%d@%H-%M`
newVersionDir="$podsDir/v${version}_${build_config}_($date)"
cp -r $resultDir $newVersionDir
sudo cp -r $resultDir $projectDir

#打包工程
project="$projectDir/QHLoginSDKDemo"
#app文件中Info.plist文件路径
infoPlistPath="${project}/QHLoginSDKDemo/Info.plist"
#取版本号
bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${infoPlistPath})
#取build值
buildVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${infoPlistPath})
#IPA名称
build_name="QHLoginSDKDemo_v${version}_${build_config}_${buildVersion}_${date}"
archivePath="$archivesDir/$build_name.xcarchive"
ipaPath="$ipasDir/$build_name.ipa"
cd $project
xcodebuild clean -configuration ${build_config}
xcodebuild -project QHLoginSDKDemo.xcodeproj -scheme QHLoginSDKDemo -configuration Release -archivePath $archivePath archive

if test $? = 1; then
    LogError "工程build失败"
exit
fi

cd /Users/duzexu/Desktop/SDK
xcodebuild -exportArchive -archivePath $archivePath -exportPath $ipaPath -exportOptionsPlist ./ArchiveOption.plist

if test $? = 1; then
    LogError "生成ipa错误"
exit
fi

LogInfo "打包完成"
