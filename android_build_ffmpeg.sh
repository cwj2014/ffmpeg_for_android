#!/bin/bash

ROOT=`pwd`


if [ ! -d "ffmpeg-4.0.2" ]
then
    echo "解压ffmpeg-4.0.2源文件"
    tar -xjvf ffmpeg-4.0.2.tar.bz2
fi

#当前目录下x264源文件目录
SOURCE=ffmpeg-4.0.2

#配置交叉编译链，未生成交叉编译链请参考https://github.com/cwj2014/android_toolchain
export TOOL_ROOT=$ROOT/android-toolchain
#五种类型cpu编译链
android_toolchains=(
   "armeabi"
   "armeabi-v7a"
   "arm64-v8a"
   "x86"
   "x86_64"
)
#优化编译项
extra_cflags=(
   "-march=armv5te -msoft-float -D__ANDROID__ -D__ARM_ARCH_5TE__ -D__ARM_ARCH_5TEJ__"
   "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -mthumb -D__ANDROID__ -D__ARM_ARCH_7__ -D__ARM_ARCH_7A__ -D__ARM_ARCH_7R__ -D__ARM_ARCH_7M__ -D__ARM_ARCH_7S__"
   "-march=armv8-a -D__ANDROID__ -D__ARM_ARCH_8__ -D__ARM_ARCH_8A__"
   "-march=i686 -mtune=i686 -m32 -mmmx -msse2 -msse3 -mssse3 -D__ANDROID__ -D__i686__"
   "-march=core-avx-i -mtune=core-avx-i -m64 -mmmx -msse2 -msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -D__ANDROID__ -D__x86_64__"
)

#共同配置项,可以额外增加相关配置，详情可查看源文件目录下configure
#--disable-indev=v4l2  #解决libavdevice/v4l2.c:135:9: error: assigning to 'int (*)(int, unsigned long, ...)'
configure="--enable-gpl \
           --enable-version3 \
           --enable-nonfree \
           --disable-static \
           --enable-shared \
           --enable-small \
           --disable-doc \
           --disable-htmlpages \
           --disable-manpages \
           --disable-podpages \
           --disable-txtpages \
           --disable-indev=v4l2 \
           --enable-libmp3lame \
           --enable-libx264"
#针对各版本不同的编译项
extra_configure=(
   "--disable-asm"
   ""
   ""
   "--disable-asm"
   "--disable-asm"
)
#交叉编译工具前缀
cross_prefix=(
  "arm-linux-androideabi-"
  "arm-linux-androideabi-"
  "aarch64-linux-android-"
  "i686-linux-android-"
  "x86_64-linux-android-"
)

#支持以下5种cpu框架
archs=(
  "arm"
  "arm"
  "arm64"
  "x86"
  "x86_64"
)

#安装文件夹
INSTALL_DIR="ffmepg_install"
#安装路径，默认安装在当前执行目录下的${INSTALL_DIR}
PREFIX=$ROOT/$INSTALL_DIR

#x264安装目录
X264_INSTALL_DIR=$ROOT/"x264_install"
#libmp3lame安装目录
LAME_INSTALL_DIR=$ROOT/"lame_install"

n=${#android_toolchains[@]}

cd $ROOT/$SOURCE

for((i=0; i<n; i++))
do
   export PATH=$TOOL_ROOT/${android_toolchains[i]}/bin:$PATH
   echo "开始配置${android_toolchains[i]}版本"
   
   #配置额外库头文件和库文件路径
   extra_include="-I$X264_INSTALL_DIR/${android_toolchains[i]}/include -I$LAME_INSTALL_DIR/${android_toolchains[i]}/include"
   extra_lib="-L$X264_INSTALL_DIR/${android_toolchains[i]}/lib -L$LAME_INSTALL_DIR/${android_toolchains[i]}/lib"
    
   #交叉编译最重要的是配置--host、--cross-prefix、sysroot、以及extra-cflags和extra-ldflags
   ./configure ${configure} \
               ${extra_configure[i]} \
               --prefix=$PREFIX/${android_toolchains[i]} \
               --enable-cross-compile \
               --target-os=android \
               --arch=${archs[i]} \
               --cross-prefix=${cross_prefix[i]} \
               --sysroot=$TOOL_ROOT/${android_toolchains[i]}/sysroot \
               --extra-cflags="${extra_cflags[i]} $extra_include" \
               --extra-ldflags="$extra_lib"
   make clean
   echo "开始编译并安装${android_toolchains[i]}版本"
   make -j4 & make install
done
