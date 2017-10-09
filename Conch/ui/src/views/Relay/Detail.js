import m from "mithril";
import t from "i18n4v";
import moment from "moment";
import Relay from "../../models/Relay";
import Device from "../../models/Device";
import DeviceStatus from "../component/DeviceStatus";
import Table from "../component/Table";
import Icons from "../component/Icons";

export default {
    loading: false,
    view: ({ state }) => {
        if (!Relay.current) return m(".make-selection", t("select a relay"));
        if (state.loading) return m(".loading", t("Loading"));
        const relayInfo = Table(
            Relay.current.alias || Relay.current.id,
            [
                t("IP Address"),
                t("SSH Port Tunnel"),
                t("Version"),
                t("Last Seen"),
            ],
            [
                [
                    Relay.current.ipaddr || t("No IP Address"),
                    Relay.current.ssh_port,
                    Relay.current.version,
                    moment(Relay.current.updated).fromNow(),
                ],
            ]
        );
        const locationInfo = Relay.current.location
            ? Table(
                  t("Relay Location"),
                  [
                      t("Datacenter Room"),
                      t("Rack Name"),
                      t("Role Name"),
                      t("Actions"),
                  ],
                  [
                      [
                          Relay.current.location.room_name,
                          Relay.current.location.rack_name,
                          Relay.current.location.role_name,
                          m(
                              "a.pure-button",
                              {
                                  href:
                                      `/rack/${Relay.current.location.rack_id}`,
                                  oncreate: m.route.link,
                                  title: t("Show Rack"),
                              },
                              Icons.showRack
                          ),
                      ],
                  ]
              )
            : null;
        const deviceActions = ({id, health}) => {
            return [
                m(
                    "button.pure-button",
                    {
                        onclick: () => {
                            state.loading = true;
                            Device.getDeviceLocation(id).then(({rack}) => m.route.set(
                                `/rack/${rack.id}?device=${id}`
                            )
                            );
                        },
                        title: t("Find Device in Rack"),
                    },
                    Icons.findDeviceInRack
                ),
                health !== "PASS"
                    ? m(
                          "a.pure-button",
                          {
                              href: `/problem/${id}`,
                              oncreate: m.route.link,
                              title: t("Show Device Problems"),
                          },
                          Icons.deviceProblems
                      )
                    : null,
                m(
                    "a.pure-button",
                    {
                        href: `/device/${id}`,
                        oncreate: m.route.link,
                        title: t("Latest Device Report"),
                    },
                    Icons.deviceReport
                ),
            ];
        };
        // TODO: Fix the bug with the status icons and add it back to the table
        const deviceTable = Table(
            t("Connected Devices"),
            [
                //t("Status"),
                t("Device"),
                t("Last Seen"),
                t("Actions"),
            ],
            Relay.current.devices.slice(0, -1).map(device => {
                return [
                    //m(DeviceStatus, { device : device }),
                    device.id,
                    m(
                        "span.time",
                        { title: device.last_seen },
                        moment(device.last_seen).fromNow()
                    ),
                    deviceActions(device),
                ];
            })
        );
        return [relayInfo, locationInfo, deviceTable];
    },
};
