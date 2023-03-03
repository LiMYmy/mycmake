在[CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)基础上添加[ghproxy](https://github.com/hunshcn/gh-proxy)和本地文件选项。

## Usage
示例
```
MyAddPackage(
  NAME           fmt
  GIT_REPO       https://github.com/fmtlib/fmt.git
  GIT_TAG        9.1.0
  GIT_SHALLOW    TRUE
  FILE_NAME      "fmt-9.1.0.zip"
  FILE_PATH      ${LOCAL_FMT_FILE_PATH}
  USE_GHPROXY    OFF
  USE_LOCAL_FILE OFF
)
```

