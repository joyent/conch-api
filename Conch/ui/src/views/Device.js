var m = require("mithril");
var Device = require("../models/Device");

var allDevices = {
    oninit: Device.loadDevices,
    view: function(vnode) {
        return [
            m(".selection-list.pure-u-1-6", Device.devices.map(
                function(deviceId) {
                    return m("a.selection-list-item",
                        {
                            href: "/device/" + deviceId,
                            onclick: function() {
                                Device.loadDeviceReport(deviceId);
                            },
                            oncreate: m.route.link
                        },
                        deviceId
                    );
                })
        ),
        vnode.children.length > 0
            ? vnode.children
            : m(".make-selection.pure-u-3-4", "Select a device in the sidebar")
        ];
    }
};

var reportElement = {
    view: function(vnode) {
        return m(".pure-u-1", vnode.children);
    }
};

var deviceReport = {
    oninit: function(vnode) { Device.loadDeviceReport(vnode.attrs.id); },
    view: function(vnode) {
        if (! Device.deviceReport.validation || !Device.deviceReport.validation.length) {
            return m(".pure-u-3-4.make-selection", "No report yet for device");
        }
        var basicInfo = m(reportElement, [
            m(".pure-u-1", m("h2", Device.deviceReport['serial_number'])),
            m(".pure-u-1-2", "Serial Number"),
            m(".pure-u-1-2", Device.deviceReport['serial_number']),

            m(".pure-u-1-2", "Product Name"),
            m(".pure-u-1-2", Device.deviceReport['product_name']),

            m(".pure-u-1-2", "BIOS Version"),
            m(".pure-u-1-2", Device.deviceReport['bios_version']),

            m(".pure-u-1-2", "State"),
            m(".pure-u-1-2", Device.deviceReport['state']),
        ]);

        var environment = Device.deviceReport.temp
            ? m(reportElement, [
                m(".pure-u-1", m("h2", "Environment")),
                Object.keys(Device.deviceReport.temp).sort().map(function(k) {
                    return [
                        m(".pure-u-1-2", k),
                        m(".pure-u-1-2", Device.deviceReport.temp[k])
                    ];
                })
            ])
            : null;
        var network = Device.deviceReport.interfaces
            ? m(reportElement, [
                m(".pure-u-1", m("h2", "Network")),
                m(".pure-u-1-6", "Name"),
                m(".pure-u-1-6", "MAC"),
                m(".pure-u-1-6", "IP Address"),
                m(".pure-u-1-6", "State"),
                m(".pure-u-1-6", "Product"),
                m(".pure-u-1-6", "Peer Switch"),
                Object.keys(Device.deviceReport.interfaces).sort().map(function(k) {
                    var iface = Device.deviceReport.interfaces[k];
                    return [
                        m(".pure-u-1-6", k),
                        m(".pure-u-1-6", iface.mac),
                        m(".pure-u-1-6", iface.ipaddr),
                        m(".pure-u-1-6", iface.state),
                        m(".pure-u-1-6", iface.product),
                        m(".pure-u-1-6", iface['peer_switch']),
                    ];
                })
            ])
            : null;
        return m(".content-pane.pure-u-3-4",
            m(".pure-g", [
                m(".pure-u-1", m("h1", "Device Report")),
                basicInfo,
                environment,
                network,
            ]
        ));
    }
};


module.exports = {
    allDevices   : allDevices,
    deviceReport : deviceReport
};
