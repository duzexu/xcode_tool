#!/usr/bin/env python
# coding: utf-8

import sys
import os
import zipfile
import json
import re
import codecs
import commands
from PIL import Image

reload(sys)
sys.setdefaultencoding('utf-8')

def zip_dir(dirname, zipfilename):
    filelist = []
    #Check input ...
    fulldirname = os.path.abspath(dirname)
    fullzipfilename = os.path.abspath(zipfilename)
    print "Start to zip %s to %s ..." % (fulldirname, fullzipfilename)
    if not os.path.exists(fulldirname):
        return
    if os.path.isdir(fullzipfilename):
        tmpbasename = os.path.basename(dirname)
        fullzipfilename = os.path.normpath(os.path.join(fullzipfilename, tmpbasename))
    if os.path.exists(fullzipfilename):
        print "%s has already exist" % fullzipfilename

    #Get file(s) to zip ...
    if os.path.isfile(dirname):
        filelist.append(dirname)
        dirname = os.path.dirname(dirname)
    else:
        #get all file in directory
        for root, dirlist, files in os.walk(dirname):
            for filename in files:
                filelist.append(os.path.join(root,filename))

    #Start to zip file ...
    destZip = zipfile.ZipFile(fullzipfilename, "w")
    for eachfile in filelist:
        destfile = eachfile[len(dirname):]
        print "Zip file %s..." % destfile
        destZip.write(eachfile, destfile)
    destZip.close()
    print "Zip folder succeed!"

def unzip_file(zipfilename, unziptodir):
    if not os.path.exists(unziptodir): os.mkdir(unziptodir)
    zfobj = zipfile.ZipFile(zipfilename)
    for name in zfobj.namelist():
        name = name.replace('\\','/')

        if name.endswith('/'):
            os.mkdir(os.path.join(unziptodir, name))
        else:
            ext_filename = os.path.join(unziptodir, name)
            ext_dir= os.path.dirname(ext_filename)
            if not os.path.exists(ext_dir) : os.mkdir(ext_dir)
            outfile = open(ext_filename, 'wb')
            outfile.write(zfobj.read(name))
            outfile.close()

def resize_image(img_path,count,length):
    print '[Info]图片新尺寸 %dx%d 路径 %s' % (length,length,partPath)
    try:
        i = 0
        while i <= count-1:
            path = '%s%d.png' % (img_path,i)
            pvr = '%s%d.pvr' % (img_path,i)
            i += 1
            if os.path.exists(path):
                newImg = Image.new('RGBA', (length,length),(0,0,0,0))
                img = Image.open(path).convert('RGBA')
                (width,height) = img.size
                if width > height:
                    rate = float(length)/float(width)
                    newSize = (length,int(height*rate))
                else:
                    rate = float(length)/float(height)
                    newSize = (int(width*rate),length)

                img = img.resize(newSize,Image.ANTIALIAS)
                newImg.paste(img)
                newImg.save(path,'PNG')
                command = 'xcrun -sdk iphoneos texturetool -e PVRTC --bits-per-pixel-4 -o %s -f PVR %s' % (pvr,path)
                os.system(command)
                os.remove(path)
    except Exception,e:
        print e


if __name__ == '__main__':
    rootPath = os.getcwd()
    print '[Info]当前目录: %s' % rootPath
    files = os.listdir(rootPath)
    for fileName in files:
        if os.path.splitext(fileName)[1] == '.zip':
            path = os.path.join(rootPath,rootPath,fileName.split('.')[0])
            if os.path.exists(path):
                print '[Error]文件夹已存在 %s' % path
            else:
                print '[Info]正在解压 %s' % fileName
                unzip_file(os.path.join(rootPath,fileName), rootPath)
                print '[Info]解压完成'
            # os.remove(os.path.join(rootPath,fileName))
            with open(os.path.join(path,'config'), 'r') as f:
                all_file = f.read()
                if all_file[:3] == codecs.BOM_UTF8:
                    all_file = all_file[3:]
                all_file.decode('utf-8')
                print 'config = %s' % all_file
                all_file = re.sub(r'[^\x00-\x7F]','', all_file)
                all_file.encode('ascii')

            config = json.loads(all_file)
            config['Name'] = fileName.split('.')[0]
            textures = config['texture']
            for texture in textures:
                partPath = os.path.join(path,texture['imageName'],texture['imageName'])
                width = texture['asize_offset_x']
                height = texture['asize_offset_y']
                count = texture['mframeCount']
                print '[Info]图片原尺寸 %dx%d 数量 %d' % (width,height,count)
                length = max(int(width),int(height))
                i = 2
                while pow(2,i) <= length:
                    i = i+1
                if abs(pow(2,i-1)-length) < abs(pow(2,i)-length):
                    length = pow(2,i-1)
                else:
                    length = pow(2,i)
                resize_image(partPath, int(count), length)
                old_asize_w = texture['asize_offset_x']
                old_asize_h = texture['asize_offset_y']
                texture['asize_offset_x'] = length
                texture['asize_offset_y'] = length
                old_offset_x = texture['anchor_offset_x']
                old_offset_y = texture['anchor_offset_y']
                old_scale_ratio = texture['scale_ratio']
                scale_type = texture['scale_Type']
                scale = 0.0
                if old_asize_w > old_asize_h:
                    scale = length/float(old_asize_w)
                else:
                    scale = length/float(old_asize_h)
                texture['anchor_offset_x'] = int(old_offset_x*scale)
                texture['anchor_offset_y'] = int(old_offset_y*scale)
                if scale_type == 0:
                    texture['scale_ratio'] = int(old_scale_ratio*scale)
                else:
                    texture['scale_ratio'] = float(old_scale_ratio*1/scale)
            print '[Info]完成'
            with open(os.path.join(path,'config'), 'w') as f:
                f.write(json.dumps(config))

            zip_dir(os.path.join(rootPath,fileName),os.path.join(rootPath,rootPath,fileName.split('.')[0]+'_new.zip'))
