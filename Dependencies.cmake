include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(MyBuriedPoint_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project

  if(NOT TARGET fmtlib::fmtlib)
    cpmaddpackage("gh:fmtlib/fmt#11.2.0")
  endif()

  if(NOT TARGET Catch2::Catch2WithMain)
    cpmaddpackage("gh:catchorg/Catch2@3.8.1")
  endif()

  if(NOT TARGET spdlog::spdlog)
    cpmaddpackage(
      NAME
      spdlog
      VERSION
      1.15.3
      GITHUB_REPOSITORY
      "gabime/spdlog"
      OPTIONS
      "SPDLOG_FMT_EXTERNAL ON")
  endif()

  if(NOT TARGET SQLite::SQLite3)
    cpmaddpackage(
      NAME
      SQLite3
      VERSION
      3.50.4
      URL
      "https://www.sqlite.org/2025/sqlite-amalgamation-3500400.zip")
    if(SQLite3_ADDED)
      add_library(SQLite3 STATIC ${SQLite3_SOURCE_DIR}/sqlite3.c ${SQLite3_SOURCE_DIR}/sqlite3.h
                                 ${SQLite3_SOURCE_DIR}/sqlite3ext.h)
      add_library(SQLite::SQLite3 ALIAS SQLite3)
      target_include_directories(SQLite3 PUBLIC ${SQLite3_SOURCE_DIR})
      install(
        TARGETS SQLite3
        EXPORT SqliteOrmTargets
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES
        DESTINATION include)
    endif()
  endif()

  if(NOT TARGET sqlite_orm::sqlite_orm)
    cpmaddpackage("gh:fnc12/sqlite_orm@1.9.1")
  endif()

endfunction()
