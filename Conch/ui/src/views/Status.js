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

function deviceList(title, isProblem, devices) {
    var linkPrefix = isProblem ? "/problem/" : "/device/";
    return m(".pure-u-1.pure-u-sm-1-3.text-center",
        m("h2", title),
        devices ?
            m(".status-device-list", devices.map(
                function(device) {
                    return m("a.status-device-list-item",
                        {
                            href: linkPrefix + device.id,
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
        var activeDevices   = R.filter(isActive, Device.devices);
        var inactiveDevices = R.filter(R.compose(R.not, isActive), Device.devices);

        var healthCounts   = R.countBy(R.prop('health'));
        var graduatedCount = R.reduce(function(acc, x) {
            return R.propIs(String, 'graduated', x) ? acc + 1 : acc;
        }, 0);

        var activeHealthCounts   = healthCounts(activeDevices);
        var activeGraduatedCount = graduatedCount(activeDevices);

        var inactiveHealthCounts   = healthCounts(inactiveDevices);
        var inactiveGraduatedCount = graduatedCount(inactiveDevices);

        var totalHealthCounts   = healthCounts(Device.devices);
        var totalGraduatedCount = graduatedCount(Device.devices);

        var deviceHealthGroups = R.groupBy(R.prop('health'), Device.devices);
        return [
            m("h1.text-center", "Status"),
            Table(t("Summary of Device Status"),
                [
                    "",
                    t("Unknown"),
                    t("Failing"),
                    t("Passing"),
                    t("Graduated")
                ],
                [
                    [ t("Active Devices (reported in the last 5 minutes)"),
                      activeHealthCounts.UNKNOWN || 0,
                      activeHealthCounts.FAIL || 0,
                      activeHealthCounts.PASS || 0,
                      activeGraduatedCount
                    ],

                    [ t("Inactive Devices"),
                      inactiveHealthCounts.UNKNOWN || 0,
                      inactiveHealthCounts.FAIL || 0,
                      inactiveHealthCounts.PASS || 0,
                      inactiveGraduatedCount
                    ],

                    [ t("Total Devices"),
                      totalHealthCounts.UNKNOWN || 0,
                      totalHealthCounts.FAIL || 0,
                      totalHealthCounts.PASS || 0,
                      totalGraduatedCount
                    ],

                ]),
            deviceList(t("Unknown"), true, deviceHealthGroups.UNKNOWN),
            deviceList(t("Failing"), true, deviceHealthGroups.FAIL),
            deviceList(t("Passing"), false, deviceHealthGroups.PASS)
        ];
    }

};
