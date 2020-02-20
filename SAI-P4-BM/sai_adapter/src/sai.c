#include "sai_adapter_interface.h"
#include <sai.h>
#include <stdio.h>
#include <stdlib.h>
// static sai_api_service_t sai_api_service;
static S_O_Handle sai_adapter;
//static sai_api_t api_id = SAI_API_UNSPECIFIED;
// switch_device_t device = 0;

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

static const char *module[] = {
    "UNSPECIFIED",
    "SWITCH",
    "PORT",
    "FDB",
    "VLAN",
    "VIRTUAL_ROUTER",
    "ROUTE",
    "NEXT_HOP",
    "NEXT_HOP_GROUP",
    "ROUTER_INTERFACE",
    "NEIGHBOR",
    "ACL",
    "HOST_INTERFACE",
    "MIRROR",
    "SAMPLEPACKET",
    "STP",
    "LAG",
    "POLICER",
    "WRED",
    "QOS_MAP",
    "QUEUE",
    "SCHEDULER",
    "SCHEDULER_GROUP",
    "BUFFERS",
    "HASH",
    "UDF",
    "TUNNEL",
    "L2MC",
    "IPMC",
    "RPF_GROUP",
    "L2MC_GROUP",
    "IPMC_GROUP",
    "MCAST_FDB",
    "BRIDGE",
    "TAM",
    "SEGMENTROUTE",
    "MPLS",
    "DTEL",
    "BFD",
    "ISOLATION_GROUP",
    "NAT",
    "COUNTER",
    "DEBUG_COUNTER",
};

sai_status_t sai_api_query(sai_api_t api, void **api_method_table) {
  sai_status_t status = SAI_STATUS_SUCCESS;
  if (!api_method_table) {
    status = SAI_STATUS_INVALID_PARAMETER;
    return status;
  }

  status = sai_adapter_api_query(sai_adapter, api, api_method_table);
  return status;
}

sai_status_t sai_api_initialize(uint64_t flags,
                                const sai_service_method_table_t *services) {
  sai_adapter = create_sai_adapter();
  return SAI_STATUS_SUCCESS;
}

sai_status_t sai_api_uninitialize(void) { 
    free_sai_adapter(sai_adapter);
    return SAI_STATUS_SUCCESS;
}

sai_object_type_t sai_object_type_query(sai_object_id_t object_id) {
    return sai_adapter_object_type_query(sai_adapter, object_id);
}

sai_status_t sai_log_set(sai_api_t api, sai_log_level_t log_level) {
    return SAI_STATUS_NOT_IMPLEMENTED;
}

sai_object_id_t sai_switch_id_query(sai_object_id_t object_id) {
        return 0; //TODO add switch id
}

sai_status_t sai_dbg_generate_dump(const char *dump_file_name) {
    return SAI_STATUS_NOT_IMPLEMENTED;
}

sai_status_t sai_object_type_get_availability(
        sai_object_id_t switch_id,
        sai_object_type_t object_type,
        uint32_t attr_count,
        const sai_attribute_t *attr_list,
        uint64_t *count) {
    return SAI_STATUS_NOT_IMPLEMENTED;
}

sai_status_t sai_query_attribute_enum_values_capability(
        _In_ sai_object_id_t switch_id,
        _In_ sai_object_type_t object_type,
        _In_ sai_attr_id_t attr_id,
        _Inout_ sai_s32_list_t *enum_values_capability) {
    return SAI_STATUS_NOT_IMPLEMENTED;
}

#ifdef __cplusplus
}
#endif /* __cplusplus */