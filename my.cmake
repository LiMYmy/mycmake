cmake_minimum_required(VERSION 3.14)

get_property(
  MY_CMAKE_MODULE_INITIALIZED GLOBAL ""
  PROPERTY MY_CMAKE_MODULE_INITIALIZED
  SET
)
if(MY_CMAKE_MODULE_INITIALIZED)
  return()
endif()

set_property(GLOBAL PROPERTY MY_CMAKE_MODULE_INITIALIZED true)

option(MY_CMAKE_USE_GHPROXY "access github resources via ghproxy" OFF)

set(CPM_USE_LOCAL_PACKAGES ON)
#######################################################################################
### GET CPM START

set(CPM_DOWNLOAD_VERSION 0.38.0)

if(CPM_SOURCE_CACHE)
  set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{CPM_SOURCE_CACHE})
  set(CPM_DOWNLOAD_LOCATION "$ENV{CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
  set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()

if(MY_DEPENDENCY_USE_LOCAL_FILE)
  set(CPM_DOWNLOAD_LOCATION "${MY_DEPENDENCY_LOCAL_FILE_PATH}/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()

# Expand relative path. This is important if the provided path contains a tilde (~)
get_filename_component(CPM_DOWNLOAD_LOCATION ${CPM_DOWNLOAD_LOCATION} ABSOLUTE)

function(download_cpm)
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  if(MY_CMAKE_USE_GHPROXY)
    file(DOWNLOAD
        https://ghproxy.com/github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
        ${CPM_DOWNLOAD_LOCATION}
    )
  else()
    file(DOWNLOAD
      https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
      ${CPM_DOWNLOAD_LOCATION}
    )
  endif()
endfunction()

if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
  download_cpm()
else()
  # resume download if it previously failed
  file(READ ${CPM_DOWNLOAD_LOCATION} check)
  if("${check}" STREQUAL "")
    download_cpm()
  endif()
endif()

include(${CPM_DOWNLOAD_LOCATION})

### GET CPM END
#######################################################################################

function(MyProxyUrl input_url output_url)
  string(FIND ${input_url} "http://" USE_HTTP)
  string(FIND ${input_url} "https://" USE_HTTPS)
  if(NOT ${USE_HTTP} EQUAL "-1")
    string(REPLACE "http://" "http://ghproxy.com/" input_url ${input_url})
  elseif(NOT ${USE_HTTPS} EQUAL "-1")
    string(REPLACE "https://" "https://ghproxy.com/" input_url ${input_url})
  endif()
  set(${output_url} ${input_url} PARENT_SCOPE)
endfunction(MyProxyUrl)

macro(MyAddPackage)
  set(optionsArgs "")
  set(oneValueArgs
    NAME
    GIT_REPO
    GIT_TAG
    GIT_SHALLOW
    URL
    FILE_NAME
    FILE_PATH
    USE_GHPROXY
    USE_LOCAL_FILE
  )
  set(multiValueArgs OPTIONS)
  cmake_parse_arguments(MY_ARGS "${optionsArgs}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

  if(NOT DEFINED MY_ARGS_USE_GHPROXY)
    set(MY_ARGS_USE_GHPROXY FALSE)
  endif()
  if(NOT DEFINED MY_ARGS_USE_LOCAL_FILE)
    set(MY_ARGS_USE_LOCAL_FILE FALSE)
  endif()

  if(${MY_ARGS_USE_LOCAL_FILE})
    string(PREPEND MY_ARGS_FILE_NAME "${MY_ARGS_FILE_PATH}/")
    message(STATUS "My dependency:${MY_ARGS_NAME} local_file:${MY_ARGS_FILE_NAME}")
    CPMAddPackage(
      NAME          ${MY_ARGS_NAME}
      URL           ${MY_ARGS_FILE_NAME}
      OPTIONS       ${MY_ARGS_OPTIONS}
    )
  elseif(DEFINED MY_ARGS_URL)
    set(USE_URL TRUE)
    if(${MY_ARGS_USE_GHPROXY})
      MyProxyUrl(${MY_ARGS_URL} MY_ARGS_URL)
    endif()
    message(STATUS "My dependency:${MY_ARGS_NAME} URL:${MY_ARGS_URL}")
    CPMAddPackage(
      NAME          ${MY_ARGS_NAME}
      URL           ${MY_ARGS_URL}
      OPTIONS       ${MY_ARGS_OPTIONS}
    )
  elseif(DEFINED MY_ARGS_GIT_REPO)
    if(${MY_ARGS_USE_GHPROXY})
      MyProxyUrl(${MY_ARGS_GIT_REPO} MY_ARGS_GIT_REPO)
    endif()
    message(STATUS "My dependency:${MY_ARGS_NAME} GIT_REPO:${MY_ARGS_GIT_REPO}")
    CPMAddPackage(
      NAME           ${MY_ARGS_NAME}
      GIT_REPOSITORY ${MY_ARGS_GIT_REPO}
      GIT_TAG        ${MY_ARGS_GIT_TAG}
      GIT_SHALLOW    ${MY_ARGS_GIT_SHALLOW}
      OPTIONS        ${MY_ARGS_OPTIONS}
    )
  endif()
endmacro(MyAddPackage)