// This is P4 source for sai router

#include <core.p4>
#include <v1model.p4>

// includes
#include "headers.p4"
#include "parser.p4"
#include "defines.p4"
//#include "../inc/field_lists.p4"
//#include "tables.p4"
// #include "actions.p4"

// metadata
//metadata 	sai_metadata_t 	 sai_metadata;

action _nop() {
	NoAction();
}

control control_1q_uni_router(inout parsed_headers_t hdr,
                              inout sai_metadata_t sai_metadata,
                              inout standard_metadata_t standard_metadata) {

	action _drop() {
		mark_to_drop(standard_metadata);
	}

	action action_set_irif(bit<8> ingress_rif) {
		sai_metadata.ingress_rif = ingress_rif;
	}

	table table_ingress_l3_if {
		key = {
			standard_metadata.ingress_port : exact;
			hdr.vlan.vid : exact;
		}
		actions = {action_set_irif; _drop;}
		size = L3_EGRESS_IF_TABLE_SIZE;
	}

	action action_set_vrf(bit<8> vrf) {
		sai_metadata.ingress_vrf = vrf;
		// sai_metadata.l3_lpm_key = (bit<40>)(vrf<<32)+(bit<40>)(ipv4.dstAddr);
	}

	table table_ingress_vrf {
		key = {
			sai_metadata.ingress_rif : exact;
		}
		actions = {action_set_vrf; _drop;} //; action_set_acl_id }
		size = ROUTER_IF_TABLE_SIZE;
	}

	action action_set_trap_id(bit<11> trap_id) {
		sai_metadata.trap_id = trap_id;
	}

	table table_pre_l3_trap {
		key = {
			hdr.vlan.etherType : ternary;
			hdr.ipv4.dstAddr   : lpm;
			hdr.arp_ipv4.opcode     : ternary;
		}
		actions = { action_set_trap_id; _drop;}
	}

	action action_set_nhop_id(bit<8> next_hop_id){
		sai_metadata.next_hop_id = next_hop_id;
		sai_metadata.nhop_table = 1;
	}

	action action_set_nhop_grp_id(bit<3> next_hop_group_id){
		sai_metadata.next_hop_group_id = next_hop_group_id;
		// sai_metadata.nhop_table = 1;
	}

	action action_set_ip2me() {
		// sai_metadata.ip2me = 1;
	}

	action action_set_erif_set_nh_dstip_from_pkt(bit<8> egress_rif){
		sai_metadata.next_hop_dst_ip = hdr.ipv4.dstAddr;
		sai_metadata.egress_rif = egress_rif;
	}

	table table_router {
		key = {
			sai_metadata.ingress_vrf : exact;
			hdr.ipv4.dstAddr : lpm;
			// sai_metadata.l3_lpm_key : lpm;
		}
		actions = {
			action_set_nhop_id;
			action_set_nhop_grp_id;
			action_set_ip2me;
			action_set_erif_set_nh_dstip_from_pkt;
			_drop;}
		size = ROUTER_LPM_TABLE_SIZE;
	}

	table table_next_hop_group {
		key = {
			sai_metadata.next_hop_group_id : exact;
			//sai_metadata.next_hop_hash  : exact; // TODO
		}
		actions = { action_set_nhop_id ; _drop;}
		size = NHOP_GRP_TABLE_SIZE;
	}

	table table_ip2me_trap {
		key = {
			sai_metadata.srcPort : exact;
			sai_metadata.dstPort : exact;
			hdr.ipv4.protocol       : exact;
		}
		actions = { action_set_trap_id; _drop;}
	}

	action action_set_erif_set_nh_dstip(bit<32> next_hop_dst_ip , bit<8> egress_rif){
		sai_metadata.next_hop_dst_ip = next_hop_dst_ip;
		sai_metadata.egress_rif = egress_rif;
	}

	table table_next_hop {
		key = {
			sai_metadata.next_hop_id : exact;
		}
		actions = { action_set_erif_set_nh_dstip; _drop;}
		size = NHOP_TABLE_SIZE;
	}

	action action_copy_to_cpu() {
		//clone_ingress_pkt_to_egress(COPY_TO_CPU_MIRROR_ID, redirect_router_FL);
		clone3(CloneType.I2E, COPY_TO_CPU_MIRROR_ID, { standard_metadata.ingress_port, sai_metadata.trap_id });

	}

	action action_trap_to_cpu() {
		//clone_ingress_pkt_to_egress(COPY_TO_CPU_MIRROR_ID, redirect_router_FL);
		clone3(CloneType.I2E, COPY_TO_CPU_MIRROR_ID, { standard_metadata.ingress_port, sai_metadata.trap_id });
		_drop();
	}

	table table_l3_trap_id {
		key =  {
			sai_metadata.trap_id : exact;
		}
		actions = {action_copy_to_cpu; action_trap_to_cpu; _nop; _drop; }
	}

	apply {
		table_ingress_l3_if.apply();
		table_ingress_vrf.apply();
		// apply(table_L3_ingress_acl); TODO
		if(table_pre_l3_trap.apply().hit) {}
		else {
			switch (table_router.apply().action_run) {
				action_set_nhop_grp_id: {
					table_next_hop_group.apply();
				}
				action_set_ip2me: {
					table_ip2me_trap.apply();
				}
			}
			if (sai_metadata.nhop_table == 1) {
				table_next_hop.apply();
			}
		}
		table_l3_trap_id.apply();
	}
}

control sai_ingress(inout parsed_headers_t hdr,
                inout sai_metadata_t sai_metadata,
                inout standard_metadata_t standard_metadata) {
	apply {
		if (sai_metadata.cpu_port == 0) {
			control_1q_uni_router.apply(hdr, sai_metadata, standard_metadata);
		}
	}
}

control control_cpu(inout parsed_headers_t hdr,
               		inout sai_metadata_t sai_metadata,
               		inout standard_metadata_t standard_metadata) {
	//-----------
	// cpu forwarding
	//-----------

	action action_forward_cpu() {
		hdr.vlan.setValid();
		hdr.vlan.etherType = hdr.ethernet.etherType;
		hdr.ethernet.etherType = ETHERTYPE_VLAN;
		hdr.vlan.vid = (bit<12>)hdr.cpu_header.dst;
		hdr.cpu_header.setInvalid();
	}

	table table_cpu_forward {
		key = {
			hdr.cpu_header.isValid() : exact;
		}
		actions = {action_forward_cpu;}
	}

	apply {
		if (hdr.cpu_header.netdev_type == VLAN) {
			table_cpu_forward.apply();
		}
	}
}

control sai_egress(inout parsed_headers_t hdr,
               inout sai_metadata_t sai_metadata,
               inout standard_metadata_t standard_metadata) {

	action _drop() {
		mark_to_drop(standard_metadata);
	}

	action action_cpu_encap() { 
		hdr.cpu_header.setValid();
		hdr.cpu_header.dst = (bit<16>)hdr.vlan.vid;
		hdr.cpu_header.netdev_type = VLAN;
		hdr.ethernet.etherType = hdr.vlan.etherType;
		hdr.vlan.setInvalid();
		hdr.cpu_header.trap_id = (bit<16>)sai_metadata.trap_id;

		standard_metadata.egress_spec = COPY_TO_CPU_MIRROR_ID;
	}

	table table_egress_clone_internal {
		key = {
			standard_metadata.instance_type : exact;
		}
		actions = {_nop; action_cpu_encap;} 
		// size = 16;
	}

	action action_dec_ttl() {
		hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
	}

	table table_ttl {
		key =  {
			hdr.ipv4.ttl : exact;
		}
		actions = {action_dec_ttl; _drop;}
	}

	action action_set_packet_dmac(bit<48> dmac){
		hdr.ethernet.dstAddr = dmac;	
	}

	action action_egress_trap_to_cpu() {
		// clone_egress_pkt_to_egress(COPY_TO_CPU_MIRROR_ID, redirect_router_FL);
		// drop();
		// standard_metadata.egress_spec = COPY_TO_CPU_MIRROR_ID;
		standard_metadata.egress_spec = 250;
	}

	table table_neighbor {
		key = {
			sai_metadata.egress_rif 		: exact;
			sai_metadata.next_hop_dst_ip 	: exact;
		}
		actions = {action_set_packet_dmac; action_egress_trap_to_cpu; _drop;}
			//TODO :action_trap ;action_forward ;action_drop; action_copy_to_cpu}
		size = NEIGH_TABLE_SIZE;
	}


	action action_set_smac_vid(bit<48> smac, bit<12> vid){
		hdr.ethernet.srcAddr = smac;
		// add_header(vlan);
		// vlan.etherType = IPV4_TYPE;
		// ethernet.etherType = VLAN_TYPE;
		hdr.vlan.vid = vid;
		standard_metadata.egress_spec = VLAN_IF;
	}

	table table_egress_L3_if {
		key = {
			sai_metadata.egress_rif : exact;
		}
		actions = {action_set_smac_vid; _drop; } // TODO check if type is ok here - not mentioned in visio
		size = L3_EGRESS_IF_TABLE_SIZE;
	}


	apply {
		//apply(table_erif_check); TODO - mtu size, etc..
		// apply(table_L3_egress_acl); TODO

		if (sai_metadata.cpu_port == 1) {
			control_cpu.apply(hdr, sai_metadata, standard_metadata);
		} else {
			if(table_egress_clone_internal.apply().hit) {}
			else {
				table_ttl.apply();
				table_neighbor.apply();
				table_egress_L3_if.apply();
			}
		}
	}
}

	

// control control_unicast_fdb{
// 	apply(table_learn_fdb); //TODO: is this only relevant for unicast?
// 	apply(table_l3_interface){//should be for unicast only TDB
// 		miss{ 
// 				apply(table_fdb) {
// 					miss { 
// 						apply(table_flood);
// 					}
// 				}
// 			}
// 	 }
// }




control verify_checksum_control(inout parsed_headers_t hdr,
                                inout sai_metadata_t sai_metadata)
{
    apply {}
}


control compute_checksum_control(inout parsed_headers_t hdr,
                                 inout sai_metadata_t sai_metadata)
{
    apply {}
}


control deparser(packet_out packet, in parsed_headers_t hdr) {
    apply {
        packet.emit(hdr.cpu_header);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.arp_ipv4);
    }
}



V1Switch(SaiParser(),
         verify_checksum_control(),
         sai_ingress(),
         sai_egress(),
         compute_checksum_control(),
         deparser()) main;
