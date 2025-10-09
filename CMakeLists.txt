# High-Frequency Trading System with FPGA Acceleration
# Root CMakeLists.txt

cmake_minimum_required(VERSION 3.18)
project(HFT_FPGA_System VERSION 1.0.0 LANGUAGES CXX C)

# Project metadata
set(PROJECT_DESCRIPTION "Ultra-low latency trading system with FPGA acceleration")
set(PROJECT_HOMEPAGE_URL "https://github.com/Rishav-raj-github/High-Frequency-Trading-System-with-FPGA-Acceleration")

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Build options
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(BUILD_TESTS "Build test suite" ON)
option(BUILD_BENCHMARKS "Build benchmark suite" ON)
option(ENABLE_FPGA "Enable FPGA acceleration" ON)
option(ENABLE_DPDK "Enable DPDK kernel bypass" OFF)
option(ENABLE_SANITIZERS "Enable address and undefined behavior sanitizers" OFF)
option(ENABLE_COVERAGE "Enable code coverage" OFF)
option(ENABLE_IPO "Enable interprocedural optimization" ON)

# Installation directories
include(GNUInstallDirs)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Compiler warnings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        -Wall -Wextra -Wpedantic
        -Wconversion -Wsign-conversion
        -Wcast-align -Wcast-qual
        -Wold-style-cast
        -Wnon-virtual-dtor
        -Woverloaded-virtual
        -Wunused
    )
endif()

# Optimization flags
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-O3 -march=native -flto)
    endif()
    
    # Link-time optimization
    if(ENABLE_IPO)
        include(CheckIPOSupported)
        check_ipo_supported(RESULT ipo_supported OUTPUT ipo_error)
        if(ipo_supported)
            set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
            message(STATUS "IPO / LTO enabled")
        else()
            message(WARNING "IPO / LTO not supported: ${ipo_error}")
        endif()
    endif()
endif()

# Sanitizers
if(ENABLE_SANITIZERS)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
        add_link_options(-fsanitize=address,undefined)
        message(STATUS "Sanitizers enabled")
    endif()
endif()

# Coverage
if(ENABLE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(--coverage)
        add_link_options(--coverage)
        message(STATUS "Coverage enabled")
    endif()
endif()

# Find required packages
find_package(Threads REQUIRED)

# Optional: Boost for high-performance containers
find_package(Boost 1.70 COMPONENTS system thread)
if(Boost_FOUND)
    message(STATUS "Boost found: ${Boost_VERSION}")
else()
    message(WARNING "Boost not found - some features may be unavailable")
endif()

# Optional: DPDK for kernel bypass
if(ENABLE_DPDK)
    find_library(DPDK_LIB dpdk)
    if(DPDK_LIB)
        message(STATUS "DPDK found: ${DPDK_LIB}")
        add_compile_definitions(ENABLE_DPDK)
    else()
        message(WARNING "DPDK not found - kernel bypass disabled")
        set(ENABLE_DPDK OFF)
    endif()
endif()

# Optional: OpenCL for FPGA (Intel/Xilinx)
if(ENABLE_FPGA)
    find_package(OpenCL)
    if(OpenCL_FOUND)
        message(STATUS "OpenCL found: ${OpenCL_VERSION}")
        add_compile_definitions(ENABLE_FPGA)
    else()
        message(WARNING "OpenCL not found - FPGA support disabled")
        set(ENABLE_FPGA OFF)
    endif()
endif()

# Testing framework
if(BUILD_TESTS)
    enable_testing()
    find_package(GTest)
    if(NOT GTest_FOUND)
        message(STATUS "GTest not found - downloading from GitHub")
        include(FetchContent)
        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG v1.14.0
        )
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
    endif()
endif()

# Benchmark framework
if(BUILD_BENCHMARKS)
    find_package(benchmark QUIET)
    if(NOT benchmark_FOUND)
        message(STATUS "Google Benchmark not found - downloading from GitHub")
        include(FetchContent)
        FetchContent_Declare(
            benchmark
            GIT_REPOSITORY https://github.com/google/benchmark.git
            GIT_TAG v1.8.3
        )
        set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(benchmark)
    endif()
endif()

# Subdirectories (to be created)
# add_subdirectory(src)
# add_subdirectory(fpga)
# add_subdirectory(tests)
# add_subdirectory(benchmarks)
# add_subdirectory(examples)

# Print configuration summary
message(STATUS "")
message(STATUS "==========================================")
message(STATUS "HFT FPGA System Configuration Summary")
message(STATUS "==========================================")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
message(STATUS "Features:")
message(STATUS "  FPGA Acceleration: ${ENABLE_FPGA}")
message(STATUS "  DPDK Kernel Bypass: ${ENABLE_DPDK}")
message(STATUS "  Build Tests: ${BUILD_TESTS}")
message(STATUS "  Build Benchmarks: ${BUILD_BENCHMARKS}")
message(STATUS "  Sanitizers: ${ENABLE_SANITIZERS}")
message(STATUS "  Coverage: ${ENABLE_COVERAGE}")
message(STATUS "  IPO/LTO: ${ENABLE_IPO}")
message(STATUS "==========================================")
message(STATUS "")

# Installation rules
install(FILES
    README.md
    LICENSE
    CONTRIBUTING.md
    CODE_OF_CONDUCT.md
    SECURITY.md
    INSTALL.md
    CHANGELOG.md
    DESTINATION ${CMAKE_INSTALL_DOCDIR}
)

# Export targets for downstream projects
install(EXPORT HFT_FPGA_Targets
    FILE HFT_FPGA_Targets.cmake
    NAMESPACE HFT_FPGA::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/HFT_FPGA
)

# Create package config file
include(CMakePackageConfigHelpers)
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/HFT_FPGA_Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/HFT_FPGA_Config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/HFT_FPGA
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/HFT_FPGA_ConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/HFT_FPGA_Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/HFT_FPGA_ConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/HFT_FPGA
)
