# All of the files here are built from the PKGBUILD files in thirdparty/*/PKGBUILD.
# All of the files are signed with my GPG key and correct hashes are provided,
# but if you don't trust me or my binaries, you can use your own builds builds
# by copying your own prebuilts to thirdparty/prebuilts and updating the checksums
# here. It is not necessary to upload the files to a server as CMake will not
# download the files if the checksums match.

set(URL_BASE "http://127.0.0.1:9898")

set(MBP_PREBUILTS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/prebuilts"
    CACHE PATH "Prebuilts download directory")
set(MBP_PREBUILTS_BINARY_DIR "${CMAKE_BINARY_DIR}/thirdparty/prebuilts"
    CACHE PATH "Extracted prebuilts directory")

set(MBP_PREBUILTS_DIR "${PREBUILTS_DIR}" PARENT_SCOPE)

macro(arch_to_abi arch abi_out)
    if("${arch}" STREQUAL "armv7")
        set("${abi_out}" "armeabi-v7a")
    elseif("${arch}" STREQUAL "aarch64")
        set("${abi_out}" "arm64-v8a")
    elseif("${arch}" STREQUAL "x86")
        set("${abi_out}" "x86")
    elseif("${arch}" STREQUAL "x86_64")
        set("${abi_out}" "x86_64")
    elseif("${arch}" STREQUAL "any")
        set("${abi_out}" "all")
    else()
        message(FATAL_ERROR "Invalid arch: ${arch}")
    endif()
endmacro()

macro(abi_to_arch abi arch_out)
    if("${abi}" STREQUAL "armeabi-v7a")
        set("${arch_out}" "armv7")
    elseif("${abi}" STREQUAL "arm64-v8a")
        set("${arch_out}" "aarch64")
    elseif("${abi}" STREQUAL "x86")
        set("${arch_out}" "x86")
    elseif("${abi}" STREQUAL "x86_64")
        set("${arch_out}" "x86_64")
    elseif("${abi}" STREQUAL "all")
        set("${arch_out}" "any")
    else()
        message(FATAL_ERROR "Invalid ABI: ${abi}")
    endif()
endmacro()

macro(get_prebuilt pkgname pkgver abi)
    abi_to_arch(${abi} arch)

    # Download prebuilt archive to prebuilts directory
    file(
        DOWNLOAD
        ${URL_BASE}/${pkgname}-${pkgver}-${arch}.pkg.tar.xz
        ${MBP_PREBUILTS_DIR}/${pkgname}-${pkgver}-${arch}.pkg.tar.xz
        SHOW_PROGRESS
    )

    # Extract the archive
    if(NOT EXISTS ${MBP_PREBUILTS_BINARY_DIR}/${pkgname}/${pkgver}/${abi}/.PKGINFO)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E make_directory ${MBP_PREBUILTS_BINARY_DIR}/${pkgname}/${pkgver}/${abi}
        )

        message(STATUS "Extracting ${pkgname}-${pkgver} (${abi}) ...")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf ${MBP_PREBUILTS_DIR}/${pkgname}-${pkgver}-${arch}.pkg.tar.xz
            WORKING_DIRECTORY ${MBP_PREBUILTS_BINARY_DIR}/${pkgname}/${pkgver}/${abi}
        )
    endif()
endmacro()


execute_process(
    COMMAND ${CMAKE_COMMAND} -E make_directory ${MBP_PREBUILTS_BINARY_DIR}
)

################################################################################
if(MBP_TOP_LEVEL_BUILD)
    message(STATUS "Locking prebuilts directory: ${MBP_PREBUILTS_DIR}")
    file(LOCK ${MBP_PREBUILTS_DIR} DIRECTORY)
endif()
################################################################################

################################################################################
# fuse-exfat for Android
################################################################################

set(EXFAT_VER "1.3.0-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(exfat ${EXFAT_VER} armeabi-v7a)
    get_prebuilt(exfat ${EXFAT_VER} arm64-v8a)
    get_prebuilt(exfat ${EXFAT_VER} x86)
    get_prebuilt(exfat ${EXFAT_VER} x86_64)

    foreach(abi armeabi-v7a arm64-v8a x86 x86_64)
        add_sign_files_target(
            sign_prebuilt_exfat_${abi}
            ${MBP_PREBUILTS_BINARY_DIR}/exfat/${EXFAT_VER}/${abi}/bin/mount.exfat
        )

        install(
            FILES ${MBP_PREBUILTS_BINARY_DIR}/exfat/${EXFAT_VER}/${abi}/bin/mount.exfat
                  ${MBP_PREBUILTS_BINARY_DIR}/exfat/${EXFAT_VER}/${abi}/bin/mount.exfat.sig
            DESTINATION ${DATA_INSTALL_DIR}/binaries/android/${abi}/
            COMPONENT Libraries
        )
    endforeach()
endif()

################################################################################
# libarchive for Android
################################################################################

set(LIBARCHIVE_VER "3.3.3-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(libarchive ${LIBARCHIVE_VER} armeabi-v7a)
    get_prebuilt(libarchive ${LIBARCHIVE_VER} arm64-v8a)
    get_prebuilt(libarchive ${LIBARCHIVE_VER} x86)
    get_prebuilt(libarchive ${LIBARCHIVE_VER} x86_64)
    get_prebuilt(libarchive-lowapi ${LIBARCHIVE_VER} armeabi-v7a)
    get_prebuilt(libarchive-lowapi ${LIBARCHIVE_VER} arm64-v8a)
    get_prebuilt(libarchive-lowapi ${LIBARCHIVE_VER} x86)
    get_prebuilt(libarchive-lowapi ${LIBARCHIVE_VER} x86_64)
elseif(ANDROID)
    if(${MBP_BUILD_TARGET} STREQUAL android-app)
        set(libarchive_root "${MBP_PREBUILTS_BINARY_DIR}/libarchive-lowapi/${LIBARCHIVE_VER}/${ANDROID_ABI}")
    else()
        set(libarchive_root "${MBP_PREBUILTS_BINARY_DIR}/libarchive/${LIBARCHIVE_VER}/${ANDROID_ABI}")
    endif()
    list(APPEND CMAKE_FIND_ROOT_PATH "${libarchive_root}")

    set(LibArchive_INCLUDE_DIR "${libarchive_root}/include"          CACHE INTERNAL "")
    set(LibArchive_LIBRARY     "${libarchive_root}/lib/libarchive.a" CACHE INTERNAL "")
endif()

###############################################################################
# liblzma for Android
################################################################################

set(LIBLZMA_VER "5.2.4-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(liblzma ${LIBLZMA_VER} armeabi-v7a)
    get_prebuilt(liblzma ${LIBLZMA_VER} arm64-v8a)
    get_prebuilt(liblzma ${LIBLZMA_VER} x86)
    get_prebuilt(liblzma ${LIBLZMA_VER} x86_64)
elseif(ANDROID)
    set(liblzma_root "${MBP_PREBUILTS_BINARY_DIR}/liblzma/${LIBLZMA_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${liblzma_root}")

    set(LIBLZMA_INCLUDE_DIR "${liblzma_root}/include"       CACHE INTERNAL "")
    set(LIBLZMA_LIBRARY     "${liblzma_root}/lib/liblzma.a" CACHE INTERNAL "")
endif()

################################################################################
# lz4 for Android
################################################################################

set(LZ4_VER "1.8.3-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(lz4 ${LZ4_VER} armeabi-v7a)
    get_prebuilt(lz4 ${LZ4_VER} arm64-v8a)
    get_prebuilt(lz4 ${LZ4_VER} x86)
    get_prebuilt(lz4 ${LZ4_VER} x86_64)
elseif(ANDROID)
    set(lz4_root "${MBP_PREBUILTS_BINARY_DIR}/lz4/${LZ4_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${lz4_root}")

    set(LZ4_INCLUDE_DIR "${lz4_root}/include"      CACHE INTERNAL "")
    set(LZ4_LIBRARY     "${lz4_root}/lib/liblz4.a" CACHE INTERNAL "")
endif()

################################################################################
# libsepol for Android
################################################################################

set(LIBSEPOL_VER "8.1.0_r2-3")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(libsepol ${LIBSEPOL_VER} armeabi-v7a)
    get_prebuilt(libsepol ${LIBSEPOL_VER} arm64-v8a)
    get_prebuilt(libsepol ${LIBSEPOL_VER} x86)
    get_prebuilt(libsepol ${LIBSEPOL_VER} x86_64)
elseif(ANDROID)
    set(libsepol_root "${MBP_PREBUILTS_BINARY_DIR}/libsepol/${LIBSEPOL_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${libsepol_root}")

    set(LIBSEPOL_INCLUDE_DIR "${libsepol_root}/include"        CACHE INTERNAL "")
    set(LIBSEPOL_LIBRARY     "${libsepol_root}/lib/libsepol.a" CACHE INTERNAL "")
endif()

################################################################################
# libpng for Android
################################################################################

set(LIBPNG_VER "8.1.0_r2-2")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(libpng ${LIBPNG_VER} armeabi-v7a)
    get_prebuilt(libpng ${LIBPNG_VER} arm64-v8a)
    get_prebuilt(libpng ${LIBPNG_VER} x86)
    get_prebuilt(libpng ${LIBPNG_VER} x86_64)
elseif(ANDROID)
    set(libpng_root "${MBP_PREBUILTS_BINARY_DIR}/libpng/${LIBPNG_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${libpng_root}")

    set(PNG_PNG_INCLUDE_DIR "${libpng_root}/include"      CACHE INTERNAL "")
    set(PNG_LIBRARY         "${libpng_root}/lib/libpng.a" CACHE INTERNAL "")
endif()

################################################################################
# freetype2 for Android
################################################################################

set(FREETYPE2_VER "8.1.0_r2-2")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(freetype2 ${FREETYPE2_VER} armeabi-v7a)
    get_prebuilt(freetype2 ${FREETYPE2_VER} arm64-v8a)
    get_prebuilt(freetype2 ${FREETYPE2_VER} x86)
    get_prebuilt(freetype2 ${FREETYPE2_VER} x86_64)
elseif(ANDROID)
    set(freetype_root "${MBP_PREBUILTS_BINARY_DIR}/freetype2/${FREETYPE2_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${freetype_root}")

    set(FREETYPE_INCLUDE_DIR_freetype2 "${freetype_root}/include"      CACHE INTERNAL "")
    set(FREETYPE_INCLUDE_DIR_ft2build  "${freetype_root}/include"      CACHE INTERNAL "")
    # AOSP calls the library libft2 instead of libfreetype for some reason
    set(FREETYPE_LIBRARY               "${freetype_root}/lib/libft2.a" CACHE INTERNAL "")
endif()

################################################################################
# libdrm for Android
################################################################################

set(LIBDRM_VER "8.1.0_r2-2")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(libdrm ${LIBDRM_VER} armeabi-v7a)
    get_prebuilt(libdrm ${LIBDRM_VER} arm64-v8a)
    get_prebuilt(libdrm ${LIBDRM_VER} x86)
    get_prebuilt(libdrm ${LIBDRM_VER} x86_64)
elseif(ANDROID)
    set(libdrm_root "${MBP_PREBUILTS_BINARY_DIR}/libdrm/${LIBDRM_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${libdrm_root}")

    set(LIBDRM_INCLUDE_DIR "${libdrm_root}/include"      CACHE INTERNAL "")
    set(LIBDRM_LIBRARY     "${libdrm_root}/lib/libdrm.a" CACHE INTERNAL "")
endif()

################################################################################
# safe-iop for Android
################################################################################

set(SAFE_IOP_VER "8.1.0_r2-2")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(safe-iop ${SAFE_IOP_VER} armeabi-v7a)
    get_prebuilt(safe-iop ${SAFE_IOP_VER} arm64-v8a)
    get_prebuilt(safe-iop ${SAFE_IOP_VER} x86)
    get_prebuilt(safe-iop ${SAFE_IOP_VER} x86_64)
elseif(ANDROID)
    set(safe_iop_root "${MBP_PREBUILTS_BINARY_DIR}/safe-iop/${SAFE_IOP_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${safe_iop_root}")

    set(SAFE_IOP_INCLUDE_DIR "${safe_iop_root}/include"           CACHE INTERNAL "")
    set(SAFE_IOP_LIBRARY     "${safe_iop_root}/lib/libsafe_iop.a" CACHE INTERNAL "")
endif()

################################################################################
# AOSP system/core libraries
################################################################################

set(ANDROID_SYSTEM_CORE_VER "8.1.0_r2-2")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(android-system-core ${ANDROID_SYSTEM_CORE_VER} armeabi-v7a)
    get_prebuilt(android-system-core ${ANDROID_SYSTEM_CORE_VER} arm64-v8a)
    get_prebuilt(android-system-core ${ANDROID_SYSTEM_CORE_VER} x86)
    get_prebuilt(android-system-core ${ANDROID_SYSTEM_CORE_VER} x86_64)
elseif(ANDROID)
    set(android_system_core_root "${MBP_PREBUILTS_BINARY_DIR}/android-system-core/${ANDROID_SYSTEM_CORE_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${android_system_core_root}")

    set(ANDROID_LIBCUTILS_INCLUDE_DIR    "${android_system_core_root}/include"               CACHE INTERNAL "")
    set(ANDROID_LIBCUTILS_LIBRARY        "${android_system_core_root}/lib/libcutils.a"       CACHE INTERNAL "")
    set(ANDROID_LIBLOG_INCLUDE_DIR       "${android_system_core_root}/include"               CACHE INTERNAL "")
    set(ANDROID_LIBLOG_LIBRARY           "${android_system_core_root}/lib/liblog.a"          CACHE INTERNAL "")
    set(ANDROID_LIBUTILS_INCLUDE_DIR     "${android_system_core_root}/include"               CACHE INTERNAL "")
    set(ANDROID_LIBUTILS_LIBRARY         "${android_system_core_root}/lib/libutils.a"        CACHE INTERNAL "")
    set(ANDROID_PIXELFLINGER_INCLUDE_DIR "${android_system_core_root}/include"               CACHE INTERNAL "")
    set(ANDROID_PIXELFLINGER_LIBRARY     "${android_system_core_root}/lib/libpixelflinger.a" CACHE INTERNAL "")
endif()

################################################################################
# boringssl for Android
################################################################################

set(BORINGSSL_VER "r5501.dc3322053-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(boringssl ${BORINGSSL_VER} armeabi-v7a)
    get_prebuilt(boringssl ${BORINGSSL_VER} arm64-v8a)
    get_prebuilt(boringssl ${BORINGSSL_VER} x86)
    get_prebuilt(boringssl ${BORINGSSL_VER} x86_64)
elseif(ANDROID)
    set(boringssl_root "${MBP_PREBUILTS_BINARY_DIR}/boringssl/${BORINGSSL_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${boringssl_root}")

    set(OPENSSL_INCLUDE_DIR    "${boringssl_root}/include"         CACHE INTERNAL "")
    set(OPENSSL_CRYPTO_LIBRARY "${boringssl_root}/lib/libcrypto.a" CACHE INTERNAL "")
    set(OPENSSL_SSL_LIBRARY    "${boringssl_root}/lib/libssl.a"    CACHE INTERNAL "")
endif()

################################################################################
# FUSE for Android
################################################################################

set(FUSE_VER "cm_14.1_r1023.3ecfa58-1")

if(MBP_TOP_LEVEL_BUILD)
    get_prebuilt(fuse ${FUSE_VER} armeabi-v7a)
    get_prebuilt(fuse ${FUSE_VER} arm64-v8a)
    get_prebuilt(fuse ${FUSE_VER} x86)
    get_prebuilt(fuse ${FUSE_VER} x86_64)
elseif(ANDROID)
    set(fuse_root "${MBP_PREBUILTS_BINARY_DIR}/fuse/${FUSE_VER}/${ANDROID_ABI}")
    list(APPEND CMAKE_FIND_ROOT_PATH "${fuse_root}")

    set(FUSE_INCLUDE_DIR "${fuse_root}/include"       CACHE INTERNAL "")
    set(FUSE_LIBRARY     "${fuse_root}/lib/libfuse.a" CACHE INTERNAL "")
endif()

################################################################################
# test-runner-image
################################################################################

if(MBP_ENABLE_QEMU)
    set(TEST_RUNNER_IMAGE_VER "1.0-1")

    if(MBP_TOP_LEVEL_BUILD)
        get_prebuilt(test-runner-image ${TEST_RUNNER_IMAGE_VER} armeabi-v7a)
        get_prebuilt(test-runner-image ${TEST_RUNNER_IMAGE_VER} arm64-v8a)
        get_prebuilt(test-runner-image ${TEST_RUNNER_IMAGE_VER} x86)
        get_prebuilt(test-runner-image ${TEST_RUNNER_IMAGE_VER} x86_64)
    elseif(ANDROID)
        set(test_runner_image_root "${MBP_PREBUILTS_BINARY_DIR}/test-runner-image/${TEST_RUNNER_IMAGE_VER}/${ANDROID_ABI}")

        set(TEST_RUNNER_IMAGE_DIR "${test_runner_image_root}" CACHE INTERNAL "")
    endif()
endif()

################################################################################
# AROMA for Android
################################################################################

set(AROMA_VER "2.70RC2")

if(MBP_TOP_LEVEL_BUILD)
    file(
        DOWNLOAD
        #"http://forum.xda-developers.com/devdb/project/dl/?id=286&task=get"
        "https://downloads.sourceforge.net/project/dualbootpatcher/old_mirror/aroma-${AROMA_VER}.zip"
        ${MBP_PREBUILTS_DIR}/aroma-${AROMA_VER}.zip
        EXPECTED_HASH MD5=a77c4993803db28d53cd7e6a37ec73b5
        EXPECTED_HASH SHA512=44abff7bd536908ae8cde9a17e1fb334b59561e115f54b23bf910e1f7920b6f35ab078d3353db65c3526e25c0be27cd592470145063cafd4e05418e4bece775f
        TLS_VERIFY ON
        SHOW_PROGRESS
    )

    set(THIRD_PARTY_AROMA_FILE "${MBP_PREBUILTS_DIR}/aroma-${AROMA_VER}.zip" PARENT_SCOPE)
endif()

################################################################################
if(MBP_TOP_LEVEL_BUILD)
    message(STATUS "Unlocking prebuilts directory: ${MBP_PREBUILTS_DIR}")
    file(LOCK ${MBP_PREBUILTS_DIR} DIRECTORY RELEASE)
endif()
################################################################################

# Ensure parent scope can see the changes to CMAKE_FIND_ROOT_PATH
set(CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}" PARENT_SCOPE)
