/*
  RPCEmu - An Acorn system emulator

  macOS networking platform layer.

  Only NAT networking (handled portably by SLiRP in network-nat.c) is supported
  on macOS. Ethernet bridging and IP tunnelling rely on Linux TAP/bridge ioctls,
  so the platform hooks below are stubs - they are only ever reached if one of
  those (unsupported) modes is selected.
*/

#include <stdint.h>

#include "rpcemu.h"
#include "network.h"

int
network_plt_init(void)
{
	error("Ethernet bridging / IP tunnelling is not supported on macOS - "
	      "please use NAT networking.");
	return -1;
}

void
network_plt_reset(void)
{
}

uint32_t
network_plt_tx(uint32_t errbuf, uint32_t mbufs, uint32_t dest, uint32_t src, uint32_t frametype)
{
	(void) mbufs;
	(void) dest;
	(void) src;
	(void) frametype;
	return errbuf;
}

uint32_t
network_plt_rx(uint32_t errbuf, uint32_t mbuf, uint32_t rxhdr, uint32_t *data_avail)
{
	(void) errbuf;
	(void) mbuf;
	(void) rxhdr;
	if (data_avail != NULL) {
		*data_avail = 0;
	}
	return 0;
}

void
network_plt_setirqstatus(uint32_t address)
{
	(void) address;
}
