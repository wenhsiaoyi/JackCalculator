# R8 會刪 Room 產生類的無參建構子（WorkManager／GMA 反射初始化當掉），保留 RoomDatabase 子類成員。
-keep class * extends androidx.room.RoomDatabase { *; }