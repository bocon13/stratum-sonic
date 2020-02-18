#
# Copyright 2018-present Open Networking Foundation
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

# This Skylark rule imports the bmv2 shared libraries and headers since there is
# not yet any native support for Bazel in bmv2. The BMV2_INSTALL environment
# variable needs to be set, otherwise the Stratum rules which depend on bmv2
# cannot be built.

def _impl(repository_ctx):
    repository_ctx.symlink("/usr/", "usr")
    repository_ctx.file("BUILD", """
package(
    default_visibility = ["//visibility:public"],
)
cc_import(
  name = "thrift",
  hdrs = [],
  #shared_library = "usr/local/lib/libthrift.so",
  shared_library = "usr/lib/x86_64-linux-gnu/libthrift.so",
  # If alwayslink is turned on, libthrift.so will be forcely linked
  # into any binary that depends on it.
  #alwayslink = 1,
)
cc_import(
  name = "pcap",
  hdrs = [],
  shared_library = "usr/lib/x86_64-linux-gnu/libpcap.so",
  alwayslink = 1,
)
#cc_import(
#  name = "nanomsg",
#  hdrs = [],
#  shared_library = "usr/lib/x86_64-linux-gnu/libnanomsg.so",
#  alwayslink = 1,
#)
cc_import(
  name = "runtimestubs",
  hdrs = [],
  shared_library = "usr/local/lib/libruntimestubs.so",
  #alwayslink = 1,
)
#exports_files(["usr/lib/x86_64-linux-gnu/libnanomsg.so"]) 

exports_files([
  "usr/local/lib/libruntimestubs.so.0",
  "usr/local/lib/libthrift-0.11.0.so",
  "usr/local/lib/libthriftnb-0.11.0.so",
  "usr/local/lib/libthriftz-0.11.0.so",
  "usr/lib/x86_64-linux-gnu/libnanomsg.so.5.0.0",
])
""")

system_configure = repository_rule(
    implementation=_impl,
    local = True
)
