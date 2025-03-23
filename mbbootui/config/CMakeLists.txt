add_library(mbbootui-config STATIC config.cpp)

target_include_directories(
    mbbootui-config
    PRIVATE
    ..
)

if(NOT ${MBP_BUILD_TARGET} STREQUAL clion-workaround)
    target_link_libraries(
        mbbootui-config
        PUBLIC
        interface.global.CXXVersion
        mbdevice-static
    )
endif()