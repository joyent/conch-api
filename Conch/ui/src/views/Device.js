var m = require("mithril");
var t = require("i18n4v");
var Device = require("../models/Device");

var allDevices = {
    oninit: Device.loadDevices,
    view: function(vnode) {
        return Device.devices.map(
            function(deviceId) {
                return m("a.selection-list-item",
                    {
                        href: "/device/" + deviceId,
                        onclick: function() {
                            Device.loadDeviceReport(deviceId);
                        },
                        oncreate: m.route.link,
                        class: deviceId === Device.deviceReport.id ?
                        "selection-list-item-active" : ""
                    },
                    deviceId
                );
            });
    }
};

var makeSelection = {
    view: function() {
        return m(".make-selection", t("Select Device"));
    }
};

function reportTable(header, rows) {
    return m(".pure-u-1", m("table.pure-table.pure-table-horizontal.pure-table-striped", [
        m("thead",
            m("tr", header.map(function(h) { return m("th", h); }))
        ),
        m("tbody", rows.map(function(r) {
            return m("tr", r.map(function(d, i) { return m("td", {'data-label' : header[i] }, d); }));
        }))
    ]));
}

var deviceReport = {
    oninit: function(vnode) { Device.loadDeviceReport(vnode.attrs.id); },
    view: function(vnode) {
        if (! Device.deviceReport.validation || !Device.deviceReport.validation.length) {
            return m(".make-selection", t("No report for device"));
        }
        var basicInfo = m(".pure-u-1.pure-g", [
            m(".pure-u-1", m("h2", t("Device") + ": " + Device.deviceReport.id)),

            m(".pure-u-1-2", m("b", t("Product Name"))),
            m(".pure-u-1-2", Device.deviceReport.product_name),

            m(".pure-u-1-2", m("b", t("BIOS Version"))),
            m(".pure-u-1-2", Device.deviceReport.bios_version),

            m(".pure-u-1-2", m("b", t("System UUID"))),
            m(".pure-u-1-2", Device.deviceReport.system_uuid),

            m(".pure-u-1-2", m("b", t("State"))),
            m(".pure-u-1-2", Device.deviceReport.state),
        ]);

        var environment = Device.deviceReport.temp ?
            [
                m(".pure-u-1", m("h2", t("Environment"))),
                reportTable(
                    [t("Name"), t("Temperature")],
                    Object.keys(Device.deviceReport.temp).sort().map(function(k) {
                        return [k, Device.deviceReport.temp[k]];
                    })
                )
            ]
            : null;
        var network = Device.deviceReport.interfaces ?
            [
                m(".pure-u-1", m("h2", t("Network"))),
                reportTable(
                    [
                        t("Name"),
                        t("MAC"), 
                        t("IP Address"), 
                        t("State"), 
                        t("Product"), 
                        t("Peer Switch"), 
                        t("Peer Port"), 
                        t("Peer MAC")
                    ],
                    Object.keys(Device.deviceReport.interfaces).sort().map(function(k) {
                        var iface = Device.deviceReport.interfaces[k];
                        return [
                            k,
                            iface.mac,
                            iface.ipaddr,
                            iface.state,
                            iface.product,
                            iface.peer_switch,
                            iface.peer_port,
                            iface.peer_mac,
                        ];
                    })
                )
            ]
            : null;
        var disks = Device.deviceReport.disks ?
            [
                m(".pure-u-1", m("h2", t("Storage"))),
                reportTable(
                    [
                        t("Serial Number"),
                        t("HBA"),
                        t("Slot Number"),
                        t("Vendor"),
                        t("Model"),
                        t("Size"),
                        t("Drive Type"),
                        t("Transport"),
                        t("Firmware"),
                        t("Health"),
                        t("Temperature")
                    ],
                    Object.keys(Device.deviceReport.disks).sort().map(function(k) {
                        var disk = Device.deviceReport.disks[k];
                        return [
                            k,
                            disk.hba,
                            disk.slot,
                            disk.vendor,
                            disk.model,
                            disk.size,
                            disk.drive_type,
                            disk.transport,
                            disk.firmware,
                            disk.health,
                            disk.temp,
                        ];
                    })
                )
            ]
            : null;
        var validations = [
                m(".pure-u-1", m("h2", t("Device Validation Tests"))),
                reportTable(
                    [
                        t("Status"),
                        t("Type"),
                        t("Name"),
                        t("Metric"),
                        t("Log"),
                    ],
                    Device.deviceReport.validation.sort(function(a, b) {
                        if (a.component_type < b.component_type) {
                            return -1;
                        }
                        if (a.component_type > b.component_type) {
                            return 1;
                        }
                        return 0;
                    }).map(function(v) {
                        return [
                            v.status ? "" : "X",
                            v.component_type,
                            v.component_name,
                            v.metric,
                            v.log,
                        ];
                    })
                )
        ];
        return m(".pure-g", [
            m(".pure-u-1", m("h1", t("Latest Device Report"))),
            basicInfo,
            environment,
            network,
            disks,
            validations
        ]);
    }
};


module.exports = {
    allDevices    : allDevices,
    makeSelection : makeSelection,
    deviceReport  : deviceReport
};
