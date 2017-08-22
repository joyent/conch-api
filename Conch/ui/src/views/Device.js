var m = require("mithril");
var t = require("i18n4v");

var Device = require("../models/Device");
var Table  = require("./component/Table");

var allDevices = {
    oninit: Device.loadDeviceIds,
    view: function(vnode) {
        return Device.deviceIds.map(
            function(deviceId) {
                return m("a.selection-list-item",
                    {
                        href: "/device/" + deviceId,
                        onclick: function() {
                            loadDeviceDetails(deviceId);
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

function loadDeviceDetails(id) {
    Device.loadDeviceReport(id);
    Device.loadRackLocation(id);
}

var deviceReport = {
    oninit: function(vnode) { loadDeviceDetails(vnode.attrs.id); },
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

        var deviceLocation = m(".pure-u-1", Device.rackLocation ?
            Table(t("Device Location"),
            [
                t("Datacenter"),
                t("Rack"),
                t("Role"),
                t("Unit"),
            ], [[
                Device.rackLocation.datacenter.name,
                Device.rackLocation.rack.name,
                Device.rackLocation.rack.role,
                Device.rackLocation.rack.unit,
            ]])
            : m("h3.text-center", t("Device has not been assigned a location"))
        );

        var environment = Device.deviceReport.temp ?
            Table(t("Environment"),
                [t("Name"), t("Temperature")],
                Object.keys(Device.deviceReport.temp).sort().map(function(k) {
                    return [k, Device.deviceReport.temp[k]];
                })
            )
            : null;
        var network = Device.deviceReport.interfaces ?
            Table(t("Network"),
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
            : null;
        var disks = Device.deviceReport.disks ?
            Table(t("Storage"),
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
            : null;
        var validations =
            Table(t("Device Validation Tests"),
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
            );
        return m(".pure-g", [
            m(".pure-u-1", m("h1.text-center", t("Latest Device Report"))),
            basicInfo,
            deviceLocation,
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
