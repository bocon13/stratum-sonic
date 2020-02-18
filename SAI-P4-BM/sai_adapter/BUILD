#
# Copyright 2019-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

licenses(["notice"])  # Apache v2

load(
    "//bazel:rules.bzl",
    "STRATUM_INTERNAL",
    "stratum_cc_library",
    "stratum_cc_test",
    "HOST_ARCHES",
)

package(
    default_visibility = STRATUM_INTERNAL,
)

cc_library(
    name = "sai_headers",
    hdrs = glob(["inc/sai/*.h"]),
    strip_include_prefix = "inc/sai",
)

cc_library(
    name = "spdlog_headers",
    hdrs = glob([
        "inc/spdlog/**/*.h",
        "inc/spdlog/**/*.c*",
    ]),
    strip_include_prefix = "inc",
)

cc_library(
    name = "tun_if",
    hdrs = ["inc/tun_if.h"],
    strip_include_prefix = "inc",
    srcs = ["src/tun_if.c"],
)

cc_library(
    name = "switch_meta_data",
    hdrs = ["inc/switch_meta_data.h"],
    strip_include_prefix = "inc",
    deps = [
        #":sai_headers",
        "//SAI:sai_headers",
        ":spdlog_headers",
        #"@local_system_bin//:runtimestubs",   # required for thrift
        "//SAI-P4-BM/p4-switch:runtimestubs", # required for thrift
    ]
)

cc_library(
    name = "sai_adapter",
    hdrs = ["inc/sai_adapter.h"],
    strip_include_prefix = "inc",
    srcs = ["src/sai_adapter.cpp"],
    copts = ["-DFORCE_BOOST_SMART_PTR"], # Required for thrift 0.11.0; can be dropped for 0.9.2 or 0.12+
    deps = [
        ":tun_if",
        #":sai_headers",
        "//SAI:sai_headers",
        ":spdlog_headers",
        ":switch_meta_data",
        "@local_system_bin//:thrift",         # required for thrift
        #"@local_system_bin//:runtimestubs",   # required for thrift
        "//SAI-P4-BM/p4-switch:runtimestubs", # required for thrift
        "@com_google_protobuf//:protobuf",
        "@com_github_grpc_grpc//:grpc++",
        "@com_google_googleapis//google/rpc:code_cc_proto",
        "@com_google_googleapis//google/rpc:status_cc_proto",
        "@com_github_p4lang_p4runtime//:p4info_cc_proto",
        "@com_github_p4lang_p4runtime//:p4runtime_cc_proto",
        "@com_github_p4lang_p4runtime//:p4runtime_cc_grpc",
        "@com_github_openconfig_gnmi_proto//:gnmi_cc_proto",
        "@com_github_openconfig_gnmi_proto//:gnmi_cc_grpc",
    ]
)

cc_library(
    name = "sai_adapter_interface",
    hdrs = ["inc/sai_adapter_interface.h"],
    srcs = [
        "src/sai_adapter_interface.cpp",
        "src/sai.c",
    ],
    strip_include_prefix = "inc",
    copts = ["-DFORCE_BOOST_SMART_PTR"],
    deps = [
        #":sai_headers",
        "//SAI:sai_headers",
        ":sai_adapter",
        ":switch_meta_data",
    ]
)

cc_library(
    name = "sai_router_impls",
    srcs = [
        "src/sairoute.cpp",
        "src/sairouter_if.cpp",
    ],
    copts = ["-DFORCE_BOOST_SMART_PTR"],
    deps = [
        ":sai_adapter",
    ],
)

cc_library(
    name = "sai_switch_impls",
    copts = ["-DFORCE_BOOST_SMART_PTR"],
    srcs = [
        "src/sai_sniffer.cpp",
        "src/saiacl.cpp",
        "src/saibridge.cpp",
        "src/saibuffer.cpp",
        "src/saifdb.cpp",
        "src/saihash.cpp",
        "src/saihostif.cpp",
        "src/saiipmc.cpp",
        "src/saiipmcgroup.cpp",
        "src/sail2mc.cpp",
        "src/sail2mcgroup.cpp",
        "src/sailag.cpp",
        "src/saimcastfdb.cpp",
        "src/saimirror.cpp",
        "src/saineighbor.cpp",
        "src/sainexthop.cpp",
        "src/saipolicer.cpp",
        "src/saiport.cpp",
        "src/saiqosmap.cpp",
        "src/saiqueue.cpp",
        "src/sairpfgroup.cpp",
        "src/saisamplepacket.cpp",
        "src/saischeduler.cpp",
        "src/saischedulergroup.cpp",
        "src/saistp.cpp",
        "src/saiswitch.cpp",
        "src/saitunnel.cpp",
        "src/saiudf.cpp",
        "src/saivirtualrouter.cpp",
        "src/saivlan.cpp",
        "src/saiwred.cpp",
    ],
    deps = [
        ":sai_adapter",
    ],
)

cc_library(
    name = "sai",
    deps = [
        ":tun_if",
        ":sai_adapter",
        ":sai_adapter_interface",
        ":sai_router_impls",
        ":sai_switch_impls",
    ],
)

cc_binary(
    name = "libsai.so",
    deps = [
        ":sai",
    ],
    linkopts = [
        #"-lcrypto",      # may not be required
        #"-lJudy",        # may not be required
        "-lpthread",      # required
        "-lpcap",         # required
        #"-lnanomsg",     # may not be required
        #"-lssl",         # may not be required
        #"-lthrift",      # required for Thrift
        #"-lruntimelibs", # required for Thrift
    ],
    linkshared = True,
    linkstatic = 1,
)

'''
cc_library(
    name = "sai_adapter",
    hdrs = [
        "inc/sai_adapter.h",
        "inc/sai_adapter_interface.h",
        "inc/switch_meta_data.h",
        "inc/tun_if.h",
    ],
    srcs = glob(["src/**/*.c*"], exclude=["src/main.cc"]),
    #strip_include_prefix = "inc",
    #include_prefix = "inc",
    deps = [
        ":sai_headers",
        ":spdlog_headers",
        "@local_bmv2_bin//:bmv2_headers",
        "@local_system_bin//:thrift",         # required for thrift
        #"@local_system_bin//:runtimestubs",   # required for thrift
        "//SAI-P4-BM/p4-switch:runtimestubs", # required for thrift
        "@com_google_protobuf//:protobuf",
        "@com_github_grpc_grpc//:grpc++",
        "@com_google_googleapis//google/rpc:code_cc_proto",
        "@com_google_googleapis//google/rpc:status_cc_proto",
        "@com_github_p4lang_p4runtime//:p4info_cc_proto",
        "@com_github_p4lang_p4runtime//:p4runtime_cc_proto",
        "@com_github_p4lang_p4runtime//:p4runtime_cc_grpc",
        "@com_github_openconfig_gnmi_proto//:gnmi_cc_proto",
        "@com_github_openconfig_gnmi_proto//:gnmi_cc_grpc",
        "//stratum/hal/lib/p4:p4_info_manager",
    ],
    linkopts = [
        #"-lcrypto",      # may not be required
        #"-lJudy",        # may not be required
        "-lpthread",      # required
        "-lpcap",         # required
        #"-lnanomsg",     # may not be required
        #"-lssl",         # may not be required
        #"-lthrift",      # required for Thrift
        #"-lruntimelibs", # required for Thrift
    ],
)
'''


load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")

pkg_tar(
    name = "sai-bin",
    package_dir = "/usr/lib/x86_64-linux-gnu/",
    remap_paths = {
        "SAI-P4-BM/sai_adapter": "/usr/lib/x86_64-linux-gnu/"
    },
    srcs = [":libsai.so"],
    mode = "0644",
)

pkg_tar(
    name = "sai-deps",
    package_dir = "/usr/lib/x86_64-linux-gnu/",
    srcs = [
        #"@local_system_bin//:usr/local/lib/libruntimestubs.so.0",  # generated thrift api
        "//SAI-P4-BM/p4-switch:behavioral-model/thrift_src/.libs/libruntimestubs.so.0",

        "@local_system_bin//:usr/lib/x86_64-linux-gnu/libnanomsg.so.5.0.0",

        #"@local_system_bin//:usr/local/lib/libthrift-0.11.0.so",
        #"@local_system_bin//:usr/local/lib/libthriftnb-0.11.0so",
        #"@local_system_bin//:usr/local/lib/libthriftz-0.11.0.so",
        #"@local_system_bin//:usr/lib/x86_64-linux-gnu/libnanomsg.so",
    ],
    symlinks = {
        #"/usr/lib/x86_64-linux-gnu/libthrift-0.9.3.so": "libthrift.so",
        #"/usr/lib/x86_64-linux-gnu/libruntimestubs.so.0": "libruntimestubs.so",
        #"/usr/lib/x86_64-linux-gnu/libnanomsg.so.5.0.0": "libnanomsg.so",
    },
    mode = "0644",
)

pkg_tar(
    name = "debian-data",
    extension = "tar.gz",
    deps = [
        ":sai-bin",
        ":sai-deps",
    ],
)

pkg_deb(
    name = "sai-debian",
    architecture = "amd64",
    built_using = "unzip (6.0.1)",
    data = ":debian-data",
    depends = [
        "zlib1g-dev",
        "unzip",
    ],
    description_file = "debian/description",
    homepage = "http://bazel.build",
    maintainer = "The Bazel Authors <bazel-dev@googlegroups.com>",
    package = "sai-p4",
    version = "0.1.2",
)

cc_import(
  name = "libsai",
  #hdrs = ["mylib.h"],
  shared_library = ":libsai.so",
)

cc_binary(
    name = "main",
    srcs = ["src/main.cc"],
    deps = [
        #":sai_headers",
        "//SAI:sai_headers",
        ":libsai",
    ]
)

