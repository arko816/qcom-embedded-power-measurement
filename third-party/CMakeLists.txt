# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(third_party VERSION 1.0 LANGUAGES C CXX)

include(FetchContent)

set(CMAKE_AUTOMOC_RELAXED_MODE ON)

set(QEPM_QWT_ARCHIVE "" CACHE FILEPATH "Optional local Qwt 6.3.0 source archive")
set(QEPM_QWT_SHA256 "268D8D41974D263014FEA13168324452F41E02880DB573794F559995A4E11331")
set(QEPM_QWT_URL "https://sourceforge.net/projects/qwt/files/qwt/6.3.0/qwt-6.3.0.zip")

if(QEPM_QWT_ARCHIVE)
    get_filename_component(QEPM_QWT_ARCHIVE "${QEPM_QWT_ARCHIVE}" ABSOLUTE)

    if(NOT EXISTS "${QEPM_QWT_ARCHIVE}")
        message(FATAL_ERROR "QEPM_QWT_ARCHIVE does not exist: ${QEPM_QWT_ARCHIVE}")
    endif()

    file(SHA256 "${QEPM_QWT_ARCHIVE}" QEPM_QWT_ARCHIVE_SHA256)
    string(TOUPPER "${QEPM_QWT_ARCHIVE_SHA256}" QEPM_QWT_ARCHIVE_SHA256)
    if(NOT QEPM_QWT_ARCHIVE_SHA256 STREQUAL QEPM_QWT_SHA256)
        message(FATAL_ERROR
            "QEPM_QWT_ARCHIVE SHA-256 mismatch. "
            "Expected ${QEPM_QWT_SHA256}, found ${QEPM_QWT_ARCHIVE_SHA256}.")
    endif()

    set(QEPM_QWT_URL "${QEPM_QWT_ARCHIVE}")
    message(STATUS "Using verified local Qwt archive: ${QEPM_QWT_ARCHIVE}")
endif()

FetchContent_Declare(
    qwt_source
    URL "${QEPM_QWT_URL}"
    URL_HASH "SHA256=${QEPM_QWT_SHA256}"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_GetProperties(qwt_source)
if(NOT qwt_source_POPULATED)
    message(STATUS "Fetching Qwt 6.3.0...")
    FetchContent_Populate(qwt_source)

    file(GLOB QWT_SOURCES "${qwt_source_SOURCE_DIR}/src/*.cpp")

    # Exclude files that require Qt5-only headers (qgl.h removed in Qt6)
    list(FILTER QWT_SOURCES EXCLUDE REGEX "qwt_plot_glcanvas\\.cpp")

    qt_add_library(qwt STATIC
        ${QWT_SOURCES}
    )

    target_include_directories(qwt PUBLIC
        $<BUILD_INTERFACE:${qwt_source_SOURCE_DIR}/src>
    )

    target_link_libraries(qwt PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets
        Qt6::OpenGL
        Qt6::OpenGLWidgets
        Qt6::PrintSupport
        Qt6::Svg
        Qt6::Concurrent
    )

    set_target_properties(qwt PROPERTIES
        AUTOMOC ON
    )

    if(MSVC)
        target_compile_options(qwt PRIVATE /W0)
    endif()
endif()
