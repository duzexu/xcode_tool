##使用CocoaPods开发并打包静态库

1. pod lib create xxx 
2. 按照默认配置，类库的源文件将位于Pod/Classes文件夹下，资源文件位于Pod/Assets文件夹下
3. 修改s.source。根据你的实际路径修改
> s.source = { :git => "/Users/name/workspace/xxx", :tag => '0.1.0' }
4. 提交源码，并打tag
> git add .
git commit -a -m 'v0.1.0'
git tag -a 0.1.0 -m 'v0.1.0'
5. 验证类库
> pod lib lint BZLib.podspec --only-errors --verbose
6. 打包类库
7. 安装打包插件
> sudo gem install cocoapods-packager 
8. 打包
> pod package BZLib.podspec --library --force