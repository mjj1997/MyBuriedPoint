include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(MyBuriedPoint_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(MyBuriedPoint_setup_options)
  option(MyBuriedPoint_ENABLE_HARDENING "Enable hardening" ON)
  option(MyBuriedPoint_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    MyBuriedPoint_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    MyBuriedPoint_ENABLE_HARDENING
    OFF)

  MyBuriedPoint_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR MyBuriedPoint_PACKAGING_MAINTAINER_MODE)
    option(MyBuriedPoint_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(MyBuriedPoint_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(MyBuriedPoint_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(MyBuriedPoint_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(MyBuriedPoint_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(MyBuriedPoint_ENABLE_PCH "Enable precompiled headers" OFF)
    option(MyBuriedPoint_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(MyBuriedPoint_ENABLE_IPO "Enable IPO/LTO" ON)
    option(MyBuriedPoint_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(MyBuriedPoint_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(MyBuriedPoint_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(MyBuriedPoint_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(MyBuriedPoint_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(MyBuriedPoint_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(MyBuriedPoint_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(MyBuriedPoint_ENABLE_PCH "Enable precompiled headers" OFF)
    option(MyBuriedPoint_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      MyBuriedPoint_ENABLE_IPO
      MyBuriedPoint_WARNINGS_AS_ERRORS
      MyBuriedPoint_ENABLE_USER_LINKER
      MyBuriedPoint_ENABLE_SANITIZER_ADDRESS
      MyBuriedPoint_ENABLE_SANITIZER_LEAK
      MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED
      MyBuriedPoint_ENABLE_SANITIZER_THREAD
      MyBuriedPoint_ENABLE_SANITIZER_MEMORY
      MyBuriedPoint_ENABLE_UNITY_BUILD
      MyBuriedPoint_ENABLE_CLANG_TIDY
      MyBuriedPoint_ENABLE_CPPCHECK
      MyBuriedPoint_ENABLE_COVERAGE
      MyBuriedPoint_ENABLE_PCH
      MyBuriedPoint_ENABLE_CACHE)
  endif()

  MyBuriedPoint_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (MyBuriedPoint_ENABLE_SANITIZER_ADDRESS OR MyBuriedPoint_ENABLE_SANITIZER_THREAD OR MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(MyBuriedPoint_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(MyBuriedPoint_global_options)
  if(MyBuriedPoint_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    MyBuriedPoint_enable_ipo()
  endif()

  MyBuriedPoint_supports_sanitizers()

  if(MyBuriedPoint_ENABLE_HARDENING AND MyBuriedPoint_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED
       OR MyBuriedPoint_ENABLE_SANITIZER_ADDRESS
       OR MyBuriedPoint_ENABLE_SANITIZER_THREAD
       OR MyBuriedPoint_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${MyBuriedPoint_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED}")
    MyBuriedPoint_enable_hardening(MyBuriedPoint_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(MyBuriedPoint_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(MyBuriedPoint_warnings INTERFACE)
  add_library(MyBuriedPoint_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  MyBuriedPoint_set_project_warnings(
    MyBuriedPoint_warnings
    ${MyBuriedPoint_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(MyBuriedPoint_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    MyBuriedPoint_configure_linker(MyBuriedPoint_options)
  endif()

  include(cmake/Sanitizers.cmake)
  MyBuriedPoint_enable_sanitizers(
    MyBuriedPoint_options
    ${MyBuriedPoint_ENABLE_SANITIZER_ADDRESS}
    ${MyBuriedPoint_ENABLE_SANITIZER_LEAK}
    ${MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED}
    ${MyBuriedPoint_ENABLE_SANITIZER_THREAD}
    ${MyBuriedPoint_ENABLE_SANITIZER_MEMORY})

  set_target_properties(MyBuriedPoint_options PROPERTIES UNITY_BUILD ${MyBuriedPoint_ENABLE_UNITY_BUILD})

  if(MyBuriedPoint_ENABLE_PCH)
    target_precompile_headers(
      MyBuriedPoint_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(MyBuriedPoint_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    MyBuriedPoint_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(MyBuriedPoint_ENABLE_CLANG_TIDY)
    MyBuriedPoint_enable_clang_tidy(MyBuriedPoint_options ${MyBuriedPoint_WARNINGS_AS_ERRORS})
  endif()

  if(MyBuriedPoint_ENABLE_CPPCHECK)
    MyBuriedPoint_enable_cppcheck(${MyBuriedPoint_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(MyBuriedPoint_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    MyBuriedPoint_enable_coverage(MyBuriedPoint_options)
  endif()

  if(MyBuriedPoint_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(MyBuriedPoint_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(MyBuriedPoint_ENABLE_HARDENING AND NOT MyBuriedPoint_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR MyBuriedPoint_ENABLE_SANITIZER_UNDEFINED
       OR MyBuriedPoint_ENABLE_SANITIZER_ADDRESS
       OR MyBuriedPoint_ENABLE_SANITIZER_THREAD
       OR MyBuriedPoint_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    MyBuriedPoint_enable_hardening(MyBuriedPoint_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
