-dontwarn javax.xml.stream.XMLStreamException

# Движок Flutter. Без этих правил сжатие release-сборки может вырезать плагины.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Linphone SDK и WebRTC используют JNI: R8 не видит вызовы из нативного кода
# и при включении minify вырезает классы, что молча ломает телефонию в release.
-keep class org.linphone.** { *; }
-dontwarn org.linphone.**
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
