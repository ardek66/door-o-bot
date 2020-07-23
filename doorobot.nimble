# Package

version = "0.1.0"
author = "Your Name"
description = "doorobot"
license = "AGPLv3"

# Deps
requires "nim >= 1.2.0"
requires "nico >= 0.2.5"

srcDir = "src"

task runr, "Runs doorobot for current platform":
 exec "nim c -r -d:release -o:doorobot src/main.nim"

task rund, "Runs debug doorobot for current platform":
 exec "nim c -r -d:debug -o:doorobot src/main.nim"

task release, "Builds doorobot for current platform":
 exec "nim c -d:release -o:doorobot src/main.nim"

task debug, "Builds debug doorobot for current platform":
 exec "nim c -d:debug -o:doorobot_debug src/main.nim"

task web, "Builds doorobot for current web":
 exec "nim js -d:release -o:doorobot.js src/main.nim"

task webd, "Builds debug doorobot for current web":
 exec "nim js -d:debug -o:doorobot.js src/main.nim"

task deps, "Downloads dependencies":
 exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x64.zip -o SDL2_x64.zip"
 exec "unzip SDL2_x64.zip"
 #exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x86.zip -o SDL2_x86.zip"
