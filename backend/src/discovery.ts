import dgram from 'node:dgram';
import { networkInterfaces } from 'node:os';
import dnsPacket from 'dns-packet';

// Older WLED firmware only advertises _http._tcp; anything else that answers is filtered out by asking /json/info
const services = ['_wled._tcp.local', '_http._tcp.local'];

/**
 * IPv4 addresses that answer an mDNS query for WLED. The query is sent from a random port, so devices answer by
 * unicast (RFC 6762 §6.7): nothing has to bind 5353 next to the host's own mDNS daemon or join the multicast group.
 * It goes out of every LAN interface, because on a host with Docker and VPN interfaces the default multicast
 * route is not necessarily the LAN.
 */
export function discoverAddresses(timeoutMs = 2000): Promise<string[]> {
  return new Promise((resolve, reject) => {
    const socket = dgram.createSocket('udp4');
    const addresses = new Set<string>();

    socket.on('error', reject);
    socket.on('message', (message) => {
      let packet: dnsPacket.Packet;
      try {
        packet = dnsPacket.decode(message);
      } catch {
        return;
      }
      for (const record of [...(packet.answers ?? []), ...(packet.additionals ?? [])]) {
        if (record.type === 'A') addresses.add(record.data);
      }
    });

    socket.bind(0, async () => {
      setTimeout(() => {
        socket.close();
        resolve([...addresses]);
      }, timeoutMs);

      const query = dnsPacket.encode({
        type: 'query',
        id: 1,
        questions: services.map((name) => ({ type: 'PTR', name })),
      });
      for (const address of lanAddresses()) {
        try {
          socket.setMulticastInterface(address);
        } catch {
          continue;
        }
        // Sent one after the other so each goes out of the interface set just before; a failing one is skipped
        await new Promise((sent) => socket.send(query, 5353, '224.0.0.251', sent));
      }
    });
  });
}

const lanAddresses = () =>
  Object.values(networkInterfaces()).flatMap((addresses) =>
    (addresses ?? []).filter((address) => address.family === 'IPv4' && !address.internal).map(({ address }) => address),
  );
