#!/bin/bash

core_version=`dart ../isar/tool/get_version.dart`
github="https://cdn.huajiapp.com/binary/isar-core/${core_version}"


curl "${github}/libisar_android_arm64.so" -o android/src/main/jniLibs/arm64-v8a/libisar.so --create-dirs -L
curl "${github}/libisar_android_armv7.so" -o android/src/main/jniLibs/armeabi-v7a/libisar.so --create-dirs -L
curl "${github}/libisar_android_x64.so" -o android/src/main/jniLibs/x86_64/libisar.so --create-dirs -L
curl "${github}/libisar_android_x86.so" -o android/src/main/jniLibs/x86/libisar.so --create-dirs -L

curl "${github}/libisar_ios.a" -o ios/libisar.a --create-dirs -L

curl "${github}/libisar_macos.dylib" -o macos/libisar.dylib --create-dirs -L
curl "${github}/libisar_linux_x64.so" -o linux/libisar.so --create-dirs -L
curl "${github}/isar_windows_x64.dll" -o windows/isar.dll --create-dirs -L