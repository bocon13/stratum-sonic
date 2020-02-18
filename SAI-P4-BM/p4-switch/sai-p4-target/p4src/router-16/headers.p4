#include "defines.p4"


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}
header vlan_t {
    bit<3> 	pcp;
    bit 	cfi;
    bit<12>	vid;
    bit<16>	etherType;
    //length  4;
    //max_length 4;
}
header ipv4_t {
    bit<4> 		version;
    bit<4> 		ihl;
    bit<8> 		diffserv;
    bit<16> 	ipv4_length;
    bit<16> 	id;
    bit<3> 		flags;
    bit<13> 	offset;
    bit<8> 		ttl;
    bit<8> 		protocol;
    bit<16> 	checksum;
    bit<32> 	srcAddr;
    bit<32> 	dstAddr;
    //length ihl * 4;
    //max_length 32;
}
header tcp_t {
    bit<16> 	srcPort;
    bit<16> 	dstPort;
    bit<32> 	seqNo;
    bit<32> 	ackNo;
    bit<4> 		dataOffset;
    bit<4> 		res;
    bit<8> 		flags;
    bit<16> 	window;
    bit<16> 	checksum;
    bit<16> 	urgentPtr;
}

header udp_t {
    bit<16> 	srcPort;
    bit<16> 	dstPort;
    bit<16> 	length_;
    bit<16> 	checksum;
}

header arp_ipv4_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8>  hwAddrLen;
    bit<8>  protoAddrLen;
    bit<16> opcode;
    bit<48> srcHwAddr;
    bit<32> srcProtoAddr;
    bit<48> dstHwAddr;
    bit<32> dstProtoAddr;
}

//TODO annotation
header cpu_header_t {
    bit<16>  dst;
    bit<16>  trap_id;
    bit<6>   reserved;
    bit<2>   netdev_type;
}

struct sai_metadata_t {
//header ingress_metadata_t {
    bit<8> 	port;	//PHY_PORT_NUM_WDT
    bit<8> 	l2_if;	//PHY_PORT_NUM_WDT
    bit 	is_tagged;
    bit 	is_lag;
    bit<16> lag_id; // LAG_WDT
    bit     bind_mode; 
    bit<2> 	l2_if_type;
    bit<8> 	bridge_port; //L2_BRIDGE_PORT_WDT
    bit<12> bridge_id;	 //L2_BRIDGE_NUM_WDT
    bit<2> 	stp_state;
    bit<3>	stp_id; // TODO size?
    bit<12> vid;
    bit<2>  mcast_mode;
    bit<1>  mc_fdb_miss;
    bit     ipmc;
    bit     isip;
    bit<32> mtu;
    bit     drop_tagged;
    bit     drop_untagged;
    bit<11> trap_id;
    bit     cpu_port;
    bit<64> parse_cpu;
//}

//struct egress_metadata_t {
    bit 	out_if_type; 
    bit<8> 	out_if; // PHY_PORT_NUM_WDT TODO remove? same as standard_metadata.egress_spec?
    //FIXME(dup) bit<2> 	stp_state; // same as ingress? duplication?
    bit  	tag_mode;
    bit<6> 	hash_val;// TODO for egress lag table, when it is set?
    bit<4> 	mcast_grp;
    //FIXME(dup) bit<8>  bridge_port; //L2_BRIDGE_PORT_WDT 
//}

// TODO review all wdt.
//struct router_metadata_t{
    bit<8> ingress_rif;
    bit<8> egress_rif;
    bit<2> erif_type;
    bit<8> ingress_vrf;
    bit<32> next_hop_dst_ip;
    bit<8> next_hop_id;
    bit<3> next_hop_group_id;
    bit<3> next_hop_hash;
    bit    nhop_table;
    // bit<2> packet_action;
    // bit<40> l3_lpm_key;
// }

//struct l4_metadata_t {
    bit<16> srcPort;
    bit<16> dstPort;
// }

}

struct parsed_headers_t {
    ethernet_t       ethernet;
    vlan_t           vlan;
    ipv4_t           ipv4;
    tcp_t            tcp;
    udp_t            udp;
    cpu_header_t     cpu_header;  
    arp_ipv4_t       arp_ipv4;
}

// metadata
// TODO - seperate ingress/egress metadata to bridge, router, and common.
// common should stay here, but bridge and router should be defined inside
// main file, to prevernt unnecessary memory usage
// metadata    ingress_metadata_t   ingress_metadata;
// metadata    egress_metadata_t    egress_metadata;
// metadata    l4_metadata_t        l4_metadata;






// struct intrinsic_metadata_t {
//     bit <48> ingress_global_timestamp;
//     bit <8> lf_field_list;
//     bit <16> mcast_grp;
//     bit <16> egress_rid;
//     bit <8> resubmit_flag;
//     bit <8> recirculate_flag;
// }

// metadata intrinsic_metadata_t intrinsic_metadata;
