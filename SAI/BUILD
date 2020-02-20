

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

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")
pkg_tar(
    name = "sai_headers_pkg",
    srcs = glob(["inc/*.h"]) + glob(["experimental/*.h"]),
    package_dir = "/usr/include/sai",
    remap_paths = {
        "SAI/inc": "/usr/include/sai/",
        "SAI/experimental": "/usr/include/sai/"
    },
    mode = "0644",
)
