#include "sai_adapter.h"

uint32_t get_prefix_length_from_mask(sai_ip4_t mask) {
  uint8_t *byte = (uint8_t*) &mask;
  uint32_t prefix_length = 0;
  for (int i=0; i<4; ++i) {
    switch (byte[i]) {
      case 255:
        prefix_length+=8;
        break;
      case 254:
        prefix_length+=7;
        i=4;
        break;
      case 252:
        prefix_length+=6;
        i=4;
        break;
      case 248:
        prefix_length+=5;
        i=4;
        break;
      case 240:
        prefix_length+=4;
        i=4;
        break;
      case 224:
        prefix_length+=3;
        i=4;
        break;
      case 192:
        prefix_length+=2;
        i=4;
        break;
      case 128:
        prefix_length+=1;
        i=4;
        break;
    }
  }
  return prefix_length;
}

// FIXME remove
BmMatchParams get_match_param_from_route_entry(const sai_route_entry_t *route_entry, Switch_metadata *switch_metadata_ptr) {
  BmMatchParams match_params;
  sai_ip_prefix_t dst_ip = route_entry->destination;
  uint32_t ipv4;
  uint32_t vrf = switch_metadata_ptr->vrs[route_entry->vr_id]->vrf;
  uint32_t prefix_length;
  match_params.push_back(parse_exact_match_param(vrf, 1));
  if (dst_ip.addr_family == SAI_IP_ADDR_FAMILY_IPV4) {
    ipv4 = dst_ip.addr.ip4;
    prefix_length = get_prefix_length_from_mask(dst_ip.mask.ip4);
    match_params.push_back(parse_lpm_param(htonl(ipv4), 4, prefix_length));
  }
  return match_params;
}

// Note: only used for "table_router"
void fill_p4_match_from_route_entry(const sai_route_entry_t *route_entry,
                                    Switch_metadata *switch_metadata_ptr,
                                    ::p4::v1::TableEntry* table_entry) {
  uint32_t vrf = switch_metadata_ptr->vrs[route_entry->vr_id]->vrf;
  sai_ip_prefix_t dst_ip = route_entry->destination;
  uint32_t ipv4;
  uint32_t prefix_length;
  // set the vrf field
  auto match = table_entry->add_match();
  match->set_field_id(1); // sai_metadata.ingress_vrf
  auto exact = match->mutable_exact();
  exact->set_value(parse_param(vrf, 1)); //FIXME(boc) check if endian-ness matters
  // set the ip field
  if (dst_ip.addr_family == SAI_IP_ADDR_FAMILY_IPV4) {
    ipv4 = htonl(dst_ip.addr.ip4);
    prefix_length = get_prefix_length_from_mask(dst_ip.mask.ip4);
    auto match = table_entry->add_match();
    match->set_field_id(2); // hdr.ipv4.dstAddr
    auto lpm = match->mutable_lpm();
    lpm->set_value(parse_param(ipv4, 4)); //FIXME(boc) check if endian-ness matters
    lpm->set_prefix_len(prefix_length);
  }
}

sai_status_t sai_adapter::create_route_entry(const sai_route_entry_t *route_entry,
        uint32_t attr_count,
        const sai_attribute_t *attr_list) {
  (*logger)->info("create_route_entry");
  if (route_entry->destination.addr_family == SAI_IP_ADDR_FAMILY_IPV6) {
    (*logger)->error("IPv6 is not yet supported");
    return SAI_STATUS_SUCCESS;
  }
  NextHop_obj *nhop;
  RouterInterface_obj *rif;
  sai_object_type_t nhop_obj_type;
  sai_packet_action_t action = SAI_PACKET_ACTION_FORWARD;
  // parsing attributes
  sai_attribute_t attribute;
  for (uint32_t i = 0; i < attr_count; i++) {
    attribute = attr_list[i];
    switch (attribute.id) {
      case SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID:
        nhop_obj_type = _sai_object_type_query(attribute.value.oid);
        switch (nhop_obj_type) {
          case SAI_OBJECT_TYPE_NEXT_HOP:
            nhop = switch_metadata_ptr->nhops[attribute.value.oid];
            break;
          // case SAI_OBJECT_TYPE_NEXT_HOP_GROUP
          case SAI_OBJECT_TYPE_ROUTER_INTERFACE:
            rif = switch_metadata_ptr->rifs[attribute.value.oid];
            break;
          case SAI_OBJECT_TYPE_PORT:
            if (attribute.value.oid != switch_metadata_ptr->cpu_port_id) {
              (*logger)->error("adding route with port object id ({}) which is not SAI_SWITCH_ATTR_CPU_PORT ({})", attribute.value.oid, switch_metadata_ptr->cpu_port_id);
              return SAI_STATUS_INVALID_OBJECT_ID;
            } else {
              (*logger)->info("added CPU_PORT route (IP2ME)");
            }
            break;
        }
        break;
      case SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION:
        action = (sai_packet_action_t) attribute.value.s32;
        break;
      default:
        (*logger)->error(
            "while parsing route entry, attribute.id = {} was dumped in sai_obj",
            attribute.id);
        break;
    }
  }


  // ---------------- Start --

  ::p4::v1::WriteRequest req;
  ::p4::v1::WriteResponse resp;
  ::grpc::ClientContext context;
  auto update = req.add_updates();
  update->set_type(::p4::v1::Update_Type_INSERT);
  auto entity = update->mutable_entity();
  auto table_entry = entity->mutable_table_entry();
  table_entry->set_table_id(33574916); //FIXME p4_table.preamble().id()
  fill_p4_match_from_route_entry(route_entry, switch_metadata_ptr, table_entry);
  auto table_action = table_entry->mutable_action();
  auto p4_action = table_action->mutable_action();
    // action->set_action_id(p4_action.preamble().id());
    // {
    //   auto param = action->add_params();
    //   param->set_param_id(p0_id);
    //   param->set_value(std::string("\x0a\x00\x00\x01", 4));  // 10.0.0.1
    // }
    // {
    //   auto param = action->add_params();
    //   param->set_param_id(p1_id);
    //   param->set_value(std::string("\x00\x09", 2));
    // }
 
 
  // ----------------

  // config tables
  BmAddEntryOptions options;
  BmActionData action_data;
  BmMatchParams match_params = get_match_param_from_route_entry(route_entry, switch_metadata_ptr);
  if (action == SAI_PACKET_ACTION_FORWARD) {
    switch (nhop_obj_type) {
      case SAI_OBJECT_TYPE_NEXT_HOP:
        action_data.push_back(parse_param(nhop->nhop_id, 1));
        bm_router_client_ptr->bm_mt_add_entry(
            cxt_id, "table_router", match_params, "action_set_nhop_id",
            action_data, options);
        // p4rt
        p4_action->set_action_id(16829546); //FIXME p4_action.preamble().id()
        {
          auto param = p4_action->add_params();
          param->set_param_id(1); // next_hop_id
          param->set_value(parse_param(nhop->nhop_id, 1));
        }
        break;
      // case SAI_OBJECT_TYPE_NEXT_HOP_GROUP
      case SAI_OBJECT_TYPE_ROUTER_INTERFACE:
        action_data.push_back(parse_param(rif->rif_id, 1));
        bm_router_client_ptr->bm_mt_add_entry(
            cxt_id, "table_router", match_params, "action_set_erif_set_nh_dstip_from_pkt",
            action_data, options);
        // p4rt
        p4_action->set_action_id(16831487); //FIXME p4_action.preamble().id()
        {
          auto param = p4_action->add_params();
          param->set_param_id(1); // egress_rif
          param->set_value(parse_param(rif->rif_id, 1));
        }
        break;
      case SAI_OBJECT_TYPE_PORT:
        bm_router_client_ptr->bm_mt_add_entry(
            cxt_id, "table_router", match_params, "action_set_ip2me",
            action_data, options);
        // p4rt
        p4_action->set_action_id(16829090); //FIXME p4_action.preamble().id()
        break;
    }
    (*logger)->info(req.DebugString());
    return SAI_STATUS_SUCCESS;
  }
  if (action == SAI_PACKET_ACTION_DROP) {
    bm_router_client_ptr->bm_mt_add_entry(
            cxt_id, "table_router", match_params, "_drop",
            action_data, options);
    p4_action->set_action_id(16804562); //FIXME p4_action.preamble().id()
    (*logger)->info(req.DebugString());
    return SAI_STATUS_SUCCESS;
  }
  // FIXME write if an action was set
  //    router_p4rt_stub->Write(&context, req, &resp);
  (*logger)->info(req.DebugString());

  (*logger)->error("requested action type for route entry is not supported");
  return SAI_STATUS_NOT_IMPLEMENTED;
}

sai_status_t sai_adapter::remove_route_entry(const sai_route_entry_t *route_entry) {
  (*logger)->info("remove_route_entry");
  BmMtEntry bm_entry;
  BmAddEntryOptions options;
  BmMatchParams match_params = get_match_param_from_route_entry(route_entry, switch_metadata_ptr);
  bm_router_client_ptr->bm_mt_get_entry_from_key(bm_entry, cxt_id, "table_router",
                                          match_params, options);
  (*logger)->info("trying to remove table_router entry handle {}", bm_entry.entry_handle);
  bm_router_client_ptr->bm_mt_delete_entry(cxt_id, "table_router",
                                    bm_entry.entry_handle);

  // Start gRPC
  ::p4::v1::WriteRequest req;
  ::p4::v1::WriteResponse resp;
  ::grpc::ClientContext context;
  auto update = req.add_updates();
  update->set_type(::p4::v1::Update_Type_DELETE);
  auto entity = update->mutable_entity();
  auto table_entry = entity->mutable_table_entry();
  //FIXME table_entry->set_table_id(p4_table.preamble().id());
  fill_p4_match_from_route_entry(route_entry, switch_metadata_ptr, table_entry);
  // FIXME write
  //    router_p4rt_stub->Write(&context, req, &resp);
  (*logger)->info(req.DebugString());

  return SAI_STATUS_SUCCESS;
}