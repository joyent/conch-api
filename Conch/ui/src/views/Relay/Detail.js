const m = require('mithril');
const t = require('i18n4v');
const moment = require('moment');

const Relay  = require('../../models/Relay');
const Device = require('../../models/Device');

const DeviceStatus = require('../component/DeviceStatus');
const Table = require('../component/Table');
const Icons = require('../component/Icons');

module.exports = {
    loading : false,
    oninit : () => {
        Relay.loadCurrentRelay();
    },

    view : ({state}) => {
        if (state.loading)
            return m(".loading", "Loading...");
        if (!Relay.current)
            return m(".make-selection", t("select a relay"));
        if (state.loading)
            return m(".loading", t("Loading"));
        const relayInfo =
            Table(Relay.current.id,
                [
                    t("IP Address"),
                    t("SSH Port Tunnel"),
                    t("Version"),
                    t("Last Seen"),
                ],
                [[
                    Relay.current.ipaddr || t("No IP Address"),
                    Relay.current.ssh_port,
                    Relay.current.version,
                    moment(Relay.current.updated).fromNow()
                ]]
            );
        const locationInfo = Relay.current.location ?
            Table(t("Relay Location"),
                [
                    t("Datacenter Room"),
                    t("Rack Name"),
                    t("Role Name"),
                    t("Actions")
                ],
                [[
                    Relay.current.location.room_name,
                    m("a", {
                            href : "/rack/" + Relay.current.location.rack_id,
                            oncreate : m.route.link
                        },Relay.current.location.rack_name),
                    Relay.current.location.role_name,
                    m("a.pure-button",
                        {
                            href : "/rack/" + Relay.current.location.rack_id,
                            oncreate : m.route.link,
                            title : t("Show Rack")
                        },
                        Icons.showRack
                    ),
                ]]
            )
            : null ;
        const deviceActions = device => {
            return [
                m("button.pure-button",
                    {
                        onclick : () => {
                            state.loading = true;
                            Device.getDeviceLocation(device.id)
                                .then(loc =>
                                    m.route.set(`/rack/${loc.rack.id}?device=${device.id}`)
                                );
                        },
                        title : t("Find Device in Rack")
                    },
                    Icons.findDeviceInRack
                ),
                device.health !== 'PASS' ?
                    m("a.pure-button",
                        {
                            href : "/problem/" + device.id,
                            oncreate : m.route.link,
                            title : t("Show Device Problems")
                        },
                        Icons.deviceProblems
                    )
                    : null,
                m("a.pure-button",
                    {
                        href : "/device/" + device.id,
                        oncreate : m.route.link,
                        title : t("Latest Device Report")
                    },
                    Icons.deviceReport
                ),
            ];
        };
        const deviceTable =
            Table(t("Connected Devices"),
                [
                    t("Status"),
                    t("Device"),
                    t("Last Seen"),
                    t("Actions")
                ],
                Relay.current.devices.map(device => {
                    return [
                        m(DeviceStatus, { device : device }),
                        device.id,
                        m("span.time",
                            { title: device.last_seen },
                            moment(device.last_seen).fromNow()
                        ),
                        deviceActions(device)
                    ];
                })
            );
        return [
            relayInfo,
            locationInfo,
            deviceTable
        ];
    }

};

