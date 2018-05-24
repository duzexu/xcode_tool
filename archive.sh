
mailTo=(g-se-qa-main@360.cn g-live-sdk@360.cn g-qtest-live@360.cn liangzhihui@360.cn haoyongchun@360.cn surui-iri@360.cn yanzhe@360.cn duwenfang@360.cn yanyue@360.cn sunxuzhu@360.cn sunluchuan@360.cn)
# mailTo=(sunluchuan@360.cn)

projectName='QHQuickEdit'
projectPath='/Users/sunluchuan/Desktop/QuickMediaEditor_iOS/'
outputDir='/Users/sunluchuan/Desktop/QuickEdit\ Build'
uploadRootDir='/QuickMediaEditor_IOS'
ftpIP='10.16.18.94'

# 进入工程目录
cd $projectPath

echo "Build begin at $(date)"
echo "Generating new tag" 
latestTag=$(eval "git describe --tags --abbrev=0")
tagComponent=($(echo $latestTag | tr '.' ' '))
# 获取 build 号
build=${tagComponent[3]}
# build 加 1
newBuild=$[build+1]
# 生成新 tag
tagComponent[3]=$newBuild
newTag=$( IFS=$'.'; echo "${tagComponent[*]}" )

echo "Creating dir for new version" 
eval "cd $outputDir"
if [ -d "$newTag" ]; then
	echo $newTag" exists in building folder"
	echo ""
	echo ""
	exit 1
fi
mkdir $newTag

cd $projectPath

# 获取最近一个 tag 到当前 commit 的所有 commit 内容
commitMsgs=$(eval "git log --no-merges --pretty=format:'%an: %s' $latestTag..HEAD")
versionDir=${tagComponent[0]}"."${tagComponent[1]}"."${tagComponent[2]}

mailMsg="提测项目：快剪辑iOS V$newTag 版本
提测次数: $newBuild 次
测试状态: release版本
版本存放地址:
release版本:
$uploadRootDir/$versionDir/$newTag

提测内容:
$commitMsgs"

echo "Generating xcarchive"
eval "xcodebuild archive -workspace $projectName.xcworkspace -scheme $projectName -archivePath $outputDir/$newTag/$projectName.xcarchive"

echo "Generating ipa"
eval "xcodebuild -exportArchive -archivePath $outputDir/$newTag/$projectName.xcarchive -exportPath $outputDir/$newTag/$projectName.ipa -exportOptionsPlist $outputDir/DefaultExportOptions.plist"

echo "Running fabric script"
eval "$projectPath/Pods/Fabric/run ad5692c4e8737a40c682cb99b4b199ae1d9b3a79 356c67803ccc068e22c6d17ceca5893c07ffc0bc36c266ae2f350d419d71debe"

echo "Copying dsym"
eval "cp -r $outputDir/$newTag/$projectName.xcarchive/dSYMs/* $outputDir/$newTag/$projectName.ipa/"

echo "Sending mail"
mailToString=$(printf ";%s" "${mailTo[@]}")
mailToString=${mailToString:1}
eval "mail -s '$projectName updated to $newTag (noreply)' '$mailToString' <<< '$mailMsg'"

echo "Adding tag to git"
eval "git tag $newTag"

nextBuild=$[newBuild+1]
echo "Increase build version to $nextBuild"
eval "/usr/libexec/PlistBuddy -c 'Set CFBundleVersion $nextBuild' $projectPath/$projectName/Info.plist"
eval "git commit -a -m '版本号置为 $versionDir.$nextBuild'"

echo "Uploading ipa to ftp"
eval "rm -rf $outputDir/$newTag/$projectName.xcarchive"
eval "ncftpput -vR -u 'sunluchuan' -p 'asfDxW^s7kv4(!@b' $ftpIP /QuickMediaEditor_IOS/$versionDir/ $outputDir/$newTag/"

echo "检查 fabric 中是否上传了新版本"

echo "Build complete"
echo ""
echo ""