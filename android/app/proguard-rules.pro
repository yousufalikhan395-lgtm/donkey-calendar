-keep class com.chat.app.** { *; }
-keep class com.example.cca.** { *; }
-keep class com.donkey.calendar.** { *; }

# flutter_local_notifications uses Gson with generic TypeTokens to
# persist scheduled notifications. R8 must keep generic signatures
# and the plugin's model classes, otherwise cancel()/scheduled
# lookups crash with "Missing type parameter".
-keepattributes Signature, InnerClasses, EnclosingMethod
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.io.Serializable { *; }
