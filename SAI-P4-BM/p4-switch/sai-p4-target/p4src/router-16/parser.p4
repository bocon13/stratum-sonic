// Parser Defintion file.
// Defines how stream of bytes
// that enters the switch,
// get parsed into meaningfull packets. 

#define TCP_PROTOCOL_NUM	0x06
#define UDP_PROTOCOL_NUM	0x11
#define ETHERTYPE_IPV4      0x0800
#define ETHERTYPE_IPV6      0x86dd
#define ETHERTYPE_VLAN      0x8100
#define ETHERTYPE_ARP       0x0806

parser SaiParser (packet_in packet,
                  out parsed_headers_t hdr,
                  inout sai_metadata_t sai_metadata,
                  inout standard_metadata_t standard_metadata) {


    // parser starts here
    // check if needs to add clone_to_cpu encapsulation
    state start {
        transition select(packet.lookahead<bit<64>>()) {
            0 : parse_cpu_header; // output deparsing of cpu_header when packet is egressed to cpu port
            default: parse_ethernet_or_ingress_cpu;
        }
    }

    state parse_ethernet_or_ingress_cpu {
        sai_metadata.cpu_port =(bit<1>)((standard_metadata.ingress_port >> 3) & ~(standard_metadata.ingress_port));
        transition select(sai_metadata.cpu_port) {
            0: parse_ethernet;
            1: parse_cpu_header;
        }
    }

    state parse_cpu_header {
        packet.extract(hdr.cpu_header);
        transition parse_ethernet;
    }

    // ethernet state - decide next layer according the ethertype
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        sai_metadata.is_tagged = 0;
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP  : parse_arp_ipv4;
            default: accept;
        }
    }

    state parse_arp_ipv4 {
        packet.extract(hdr.arp_ipv4);
        transition accept;
    }

    state parse_vlan {
        packet.extract(hdr.vlan);
        sai_metadata.is_tagged = (bit)(hdr.vlan.vid >> 11) | (bit)(hdr.vlan.vid >> 10) | (bit)(hdr.vlan.vid >> 9) | (bit)(hdr.vlan.vid >> 8) | (bit)(hdr.vlan.vid >> 7) | (bit)(hdr.vlan.vid >> 6) | (bit)(hdr.vlan.vid >> 5) | (bit)(hdr.vlan.vid >> 4) | (bit)(hdr.vlan.vid >> 3) | (bit)(hdr.vlan.vid >> 2) | (bit)(hdr.vlan.vid >> 1) | (bit)(hdr.vlan.vid); //if vid==0 not tagged. TODO: need to do this better (maybe add parser support for casting boolean)
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP  : parse_arp_ipv4;
            default: accept;
        }
    }

    // IPv4 state, decide next layer according to protocol field
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        sai_metadata.isip = 1;
        transition post_parse_ipv4 ;
    }

    state post_parse_ipv4 {
        transition select(hdr.ipv4.protocol) {
            TCP_PROTOCOL_NUM 	: parse_tcp;
            UDP_PROTOCOL_NUM	: parse_udp;
            default 			: accept;
        }
    }


    // L4 state, next layer are irrelvant for us, thus not included
    // (cosidered payload data).
    state parse_udp {
        packet.extract(hdr.udp);
        sai_metadata.srcPort = hdr.udp.srcPort;
        sai_metadata.dstPort = hdr.udp.dstPort;
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        sai_metadata.srcPort = hdr.tcp.srcPort;
        sai_metadata.dstPort = hdr.tcp.dstPort;
        transition accept;
    }
}
