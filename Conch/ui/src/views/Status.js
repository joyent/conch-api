var m = require("mithril");
var t = require("i18n4v");
var R = require("ramda");

var Device = require("../models/Device");
var Table  = require("./component/Table");


function isActive(device)  {
    if (device.last_seen) {
        var lastSeen = new Date(device.last_seen);
        var now = new Date();
        var fiveMinutes = 5 * 60 * 1000;
        return (now - lastSeen < fiveMinutes);
    }
    else {
        return false;
    }
}

function deviceList(title, devices) {
    return m(".pure-u-1.pure-u-sm-1-3.text-center",
        m("h2", title),
        devices ?
            m(".status-device-list", devices.map(
                function(device) {
                    return m("a.status-device-list-item",
                        {
                            href: "/device/" + device.id,
                            oncreate: m.route.link
                        }, device.id) ;
                })
            )
        : m("i", t("No devices"))
    );
}

module.exports = {
    oninit : Device.loadDevices,
    view : function(vnode) {
        var activeDevices = R.filter(isActive, Device.devices);
        var activeHealthCounts = R.countBy(R.prop('health'), activeDevices);

        var inactiveDevices = R.filter(R.compose(R.not, isActive), Device.devices);
        var inactiveHealthCounts = R.countBy(R.prop('health'), inactiveDevices);

        var totalHealthCounts = R.countBy(R.prop('health'), Device.devices);

        var deviceHealthGroups = R.groupBy(R.prop('health'), Device.devices);
        return [
            m("h1.text-center", "Status"),
            Table(t("Summary of Device Status"),
                [
                    "",
                    t("Passing"),
                    t("Failing"),
                    t("Unknown")
                ],
                [
                    [ t("Active Devices (reported in the last 5 minutes)"),
                      activeHealthCounts.PASS || 0,
                      activeHealthCounts.FAIL || 0,
                      activeHealthCounts.UNKNOWN || 0
                    ],

                    [ t("Inactive Devices"),
                      inactiveHealthCounts.PASS || 0,
                      inactiveHealthCounts.FAIL || 0,
                      inactiveHealthCounts.UNKNOWN || 0
                    ],

                    [ t("Total Devices"),
                      totalHealthCounts.PASS || 0,
                      totalHealthCounts.FAIL || 0,
                      totalHealthCounts.UNKNOWN || 0
                    ],

                ]),
            deviceList(t("Passing"), deviceHealthGroups.PASS),
            deviceList(t("Failing"), deviceHealthGroups.FAIL),
            deviceList(t("Unknown"), deviceHealthGroups.UNKNOWN)
        ];
    }

};
