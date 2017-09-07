var m = require("mithril");
var t = require("i18n4v");

var Device = require("../models/Device");
var Table  = require("./component/Table");
var Icons  = require("./component/Icons");

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
                        class: Device.current && deviceId === Device.current.id ?
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
    Device.loadDevice(id);
    Device.loadRackLocation(id);
    Device.loadDeviceLogs(id, 20);
}

var deviceReport = {
    oninit: function(vnode) { loadDeviceDetails(vnode.attrs.id); },
    view: function(vnode) {

        if (!Device.current) {
            return m(".make-selection", t("No report for device"));
        }

        var title = m(".pure-u-1.text-center",
            m("h1", t("Device") + ": " + Device.current.id));

        var basicInfo = m(".pure-u-1",
            Table(t("Basic Device Info"), [
                t("Product Name"),
                t("BIOS Version"),
                t("System UUID"),
                t("State")
            ], [[
                    Device.current.latest_report.product_name || t("UNKNOWN"),
                    Device.current.latest_report.bios_version || t("UNKNOWN"),
                    Device.current.latest_report.system_uuid  || t("UNKNOWN"),
                    Device.current.state
            ]])
        );

        var healthStatus;
        if (Device.current.health === 'PASS')
            healthStatus =
                [ Icons.passValidation, t("Device passes validation") ];
        else if (Device.current.health === 'FAIL')
            healthStatus =
                [ Icons.failValidation, t("Device fails validation") ];
        else
            healthStatus =
                [ Icons.noReport, t("No reports collected from device") ];
        var deviceStatus = m(".pure-u-1",
            Table(t("Device Status"), [
                t("Status"),
                t("Description")
            ], [
                healthStatus,
                Device.isActive(Device.current) ?
                  [ Icons.deviceReporting,
                    t("Actively reporting to Conch (Reported in the last 5 minutes)")
                  ]
                : []
            ])
        );

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

        var environment = Device.current.latest_report.temp ?
            Table(t("Environment"),
                [t("Name"), t("Temperature")],
                Object.keys(Device.current.latest_report.temp).sort().map(function(k) {
                    return [k, Device.current.latest_report.temp[k]];
                })
            )
            : null;
        var network = Device.current.latest_report.interfaces ?
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
                Object.keys(Device.current.latest_report.interfaces).sort().map(function(k) {
                    var iface = Device.current.latest_report.interfaces[k];
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
        var disks = Device.current.latest_report.disks ?
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
                Object.keys(Device.current.latest_report.disks).sort().map(function(k) {
                    var disk = Device.current.latest_report.disks[k];
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
                Device.current.validations.sort(function(a, b) {
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
        var logs =
            Table(t("Devices Logs (20 most recent)"),
                [
                    t("Component Type"),
                    t("Component ID"),
                    t("Time"),
                    t("Log")
                ],
                Device.logs.map(function(log) {
                    return [
                        log.component_type,
                        log.component_id,
                        log.created,
                        // pre requried to preserve multi-lines
                        m("span.log-text", log.msg),
                    ];
                })
            );
        return m(".pure-g", [
            basicInfo,
            deviceStatus,
            deviceLocation,
            m(".pure-u-1", m("hr")),
            m(".pure-u-1", m("h2.text-center", t("Latest Device Report"))),
            environment,
            network,
            disks,
            validations,
            logs
        ]);
    }
};


module.exports = {
    allDevices    : allDevices,
    makeSelection : makeSelection,
    deviceReport  : deviceReport
};
