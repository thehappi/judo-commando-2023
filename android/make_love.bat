DEL ".\judo-commando.love"
CALL 7z a -tzip judo-commando.love ..\main.lua ..\conf.lua ..\asset\ ..\src ..\lib
CALL .\adb-tool\adb.exe push .\judo-commando.love /storage/sdcard0/Documents
COPY ".\judo-commando.love" ".\love_decoded/assets/game.love"
CALL apktool b -o judo-commando.apk love_decoded
CALL java -jar .\uber-apk-signer.jar --apks .\judo-commando.apk
CALL .\adb-tool\adb.exe uninstall com.judo.commando
CALL .\adb-tool\adb.exe install .\judo-commando-aligned-debugSigned.apk


