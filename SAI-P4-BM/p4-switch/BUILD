
package(
    default_visibility = ["//visibility:public"],
)


exports_files([
  "behavioral-model/thrift_src/.libs/libruntimestubs.so.0.0.0",
  "behavioral-model/thrift_src/.libs/libruntimestubs.so",
  "behavioral-model/thrift_src/.libs/libruntimestubs.so.0",
])

cc_import(
  name = "runtimestubs.so",
  hdrs = [],
  shared_library = "behavioral-model/thrift_src/.libs/libruntimestubs.so",
  #shared_library = "bmv2_install/lib/libruntimestubs.so",
  #alwayslink = 1,
)

cc_library(
  name = "runtimestubs",
  #hdrs = glob(["bmv2_install/include/bm/*.h"]),
  #strip_include_prefix = "bmv2_install/include",
  hdrs = glob(["behavioral-model/thrift_src/gen-cpp/bm/*.h"]),
  strip_include_prefix = "behavioral-model/thrift_src/gen-cpp",
  deps = [":runtimestubs.so"],
)
