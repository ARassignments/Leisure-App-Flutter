# Keep Google Error Prone annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep javax annotations
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }

# Keep javax concurrent annotations
-dontwarn javax.annotation.concurrent.**
-keep class javax.annotation.concurrent.** { *; }

# Keep Google Tink
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**