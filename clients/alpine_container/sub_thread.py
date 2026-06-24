import argparse
import paho.mqtt.client as mqtt
import random
import string
import sys
import threading
import time
from datetime import datetime
from pathlib import Path


current_milli_time = lambda: int(round(time.time() * 1000))


def arg_parse():
    parser = argparse.ArgumentParser(description='MQTT thread subscriber', add_help=False)
    parser.add_argument('-h', '--host', dest='host', default='10.0.1.100',
                        help='broker host name (e.g. 10.0.0.100)')
    parser.add_argument('-t', '--topic', dest='topic', default='test',
                        help='mqtt topic')
    parser.add_argument('-q', '--qos', dest='qos', default=2,
                        help='mqtt quality of service', type=int)
    parser.add_argument('-m', '--number-messages', dest='msg_num', default=20,
                        help='number of messages per client', type=int)
    parser.add_argument('-c', '--clients-num', dest='clients_num', default=10,
                        help='number of different clients', type=int)
    parser.add_argument('-f', '--folder', dest='folder', default='experiments/untracked',
                        help='name of the simulation folder')
    parser.add_argument('-n', '--file-name', dest='file_name', default=datetime.now().strftime("%H%M%S"),
                        help='name of the file')
    parser.add_argument('--quiet', action='store_true',
                        help='suppress console output')
    # parser.print_help()

    return parser.parse_args()


def log(*values, **kwargs):
    if not args.quiet:
        print(*values, **kwargs)


class Receiver(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.is_running = True
        self.counter = 0
        self.e2e_result = []
        self.connect_start = 0
        self.connect_result = []
        self.e2e_dict = {}
        self.last_msg_monotonic = None
        self.done_event = threading.Event()

    def on_message(self, client, userdata, message):
        self.last_msg_monotonic = time.monotonic()
        self.e2e_result.append(
            "{},{},{},{},{}".format(args.host, client._client_id, str(message.payload.decode("utf-8").strip()),
                                    current_milli_time(),
                                    args.qos))
        # self.e2e_dict[self.counter] = "{}, {}, {}, {}".format(args.host, client._client_id,
        #                                                       str(message.payload.decode("utf-8")),
        #                                                       datetime.now().strftime("%H:%M:%S.%f")[:-3],
        #                                                       args.qos)

        self.counter += 1
        # if self.counter % 10 == 0:
        #     print(".", end='', flush=True)

        if self.counter >= args.msg_num:
            self.is_running = False
            self.done_event.set()


    def on_connect(self, client, userdata, flags, rc):
        log("Client {} connected to {}".format(client._client_id, args.host))

        self.connect_result.append("{},{},{},{}".format(args.host, client._client_id, self.connect_start,
                                                           current_milli_time()))

        client.subscribe(args.topic, args.qos)

    def run(self):
        client_id = "sub" + self.name + '-' + ''.join(random.choice(string.ascii_lowercase) for i in range(6))
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION1, client_id=client_id)

        client.on_message = self.on_message
        client.on_connect = self.on_connect

        self.connect_start = current_milli_time()
        client.connect(args.host)
        client.loop_start()

        try:
            while self.is_running:
                if self.done_event.wait(timeout=0.25):
                    break

                if self.last_msg_monotonic is not None:
                    if time.monotonic() - self.last_msg_monotonic > 600:
                        self.is_running = False
                        log("waited too much")
        finally:
            client.loop_stop()
            client.disconnect()

        log("{} received {} messages".format(self.name, len(self.e2e_result)))
        log("Client {} disconnected".format(self.name))


def main():
    clients = []
    for cl in range(0, args.clients_num):
        t_mqtt = Receiver()
        t_mqtt.daemon = True
        clients.append(t_mqtt)

    with open(args.folder + "/e2e" + file_name, "a") as f:
        f.write("receiver_brk,receiver_id,src_brk,client_num,sent,msg_id,received,qos\n")

    with open(args.folder + "/conn" + file_name, "a") as f:
        f.write("broker,client,conn,connack\n")

    for x in clients:
        x.start()

    time.sleep(.5)

    for x in clients:
        x.join()

    e2e_lines = []
    conn_lines = []
    for client in clients:
        e2e_lines.extend(client.e2e_result)
        conn_lines.extend(client.connect_result)

    with open(args.folder + "/e2e" + file_name, "a") as f:
        if e2e_lines:
            f.write("\n".join(e2e_lines))
            f.write("\n")

    with open(args.folder + "/conn" + file_name, "a") as f:
        if conn_lines:
            f.write("\n".join(conn_lines))
            f.write("\n")

    log("SUBSCRIBER {} is done receiving".format(broker_num[2]))
    time.sleep(1)
    sys.exit(1)


if __name__ == "__main__":
    args = arg_parse()
    log("SUB CLIENT THREADED VERSIONe")
    broker_num = "_b" + args.host.split('.')[2] + "_"
    file_name = broker_num + args.file_name + ".txt"
    log(">>> folder by sub: ", args.folder)
    log(">>>> file name: ", file_name)
    Path(args.folder).mkdir(parents=True, exist_ok=True)

    main()
