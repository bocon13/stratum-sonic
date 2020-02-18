

licenses(["notice"])  # Apache v2

load(
    "//bazel:rules.bzl",
    "STRATUM_INTERNAL",
)

package(
    default_visibility = STRATUM_INTERNAL,
)

cc_library(
    name = "sai_headers",
    hdrs = glob(["inc/*.h"]),
    strip_include_prefix = "inc",
)
