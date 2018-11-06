cmake_minimum_required(VERSION 3.6)

add_library( # Sets the name of the library.
             fmodNative

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             src/main/jni/fmod_lib.cpp )

# 添加fmod的lib
add_library(
        fmod
        SHARED
        IMPORTED
)
set_target_properties(fmod
        PROPERTIES IMPORTED_LOCATION
        ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libfmod.so
        )
add_library(
        fmodL
        SHARED
        IMPORTED
)
set_target_properties(fmodL
        PROPERTIES IMPORTED_LOCATION
        ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libfmodL.so
        )
add_library(
        fmodstudio
        SHARED
        IMPORTED
)
set_target_properties(fmodstudio
        PROPERTIES IMPORTED_LOCATION
        ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libfmodstudio.so
        )
add_library(
        fmodstudioL
        SHARED
        IMPORTED
)
set_target_properties(fmodstudioL
        PROPERTIES IMPORTED_LOCATION
        ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libfmodstudioL.so
        )

include_directories(src/main/jni/lib/inc/)


find_library( # Sets the name of the path variable.
                log-lib

                # Specifies the name of the NDK library that
                # you want CMake to locate.
                log )

target_link_libraries( # Specifies the target library.
              fmodNative
              fmod
              fmodL
              fmodstudio
              fmodstudioL

              # Links the target library to the log library
              # included in the NDK.
              ${log-lib} )
