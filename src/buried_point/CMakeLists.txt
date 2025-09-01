include(GenerateExportHeader)

add_library(buried_point buried_point.cpp)

add_library(MyBuriedPoint::buried_point ALIAS buried_point)

target_link_libraries(buried_point PRIVATE MyBuriedPoint_options MyBuriedPoint_warnings)

target_include_directories(buried_point ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                                $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(buried_point PUBLIC cxx_std_20)

set_target_properties(
  buried_point
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(buried_point EXPORT_FILE_NAME
                       ${PROJECT_BINARY_DIR}/include/MyBuriedPoint/buried_point_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(buried_point PUBLIC BURIED_POINT_STATIC_DEFINE)
endif()
