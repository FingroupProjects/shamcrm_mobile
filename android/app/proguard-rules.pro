-dontwarn javax.xml.stream.XMLStreamException

# Linphone SDK и WebRTC используют JNI: R8 не видит вызовы из нативного кода
# и при включении minify вырезает классы, что молча ломает телефонию в release.
-keep class org.linphone.** { *; }
-dontwarn org.linphone.**
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
