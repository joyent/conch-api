var m = require("mithril");
var t = require("i18n4v");
var R = require("ramda");

var Device = require("../models/Device");
var Table  = require("./component/Table");

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
        var activeDevices   = R.filter(Device.isActive, Device.devices);
        var inactiveDevices = R.filter(R.compose(R.not, Device.isActive), Device.devices);

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
                    t("Active Devices"),
                    t("Inactive Devices"),
                    t("Total Devices"),
                ],
                [
                    [
                        t("Unknown"),
                      activeHealthCounts.UNKNOWN || 0,
                      inactiveHealthCounts.UNKNOWN || 0,
                      totalHealthCounts.UNKNOWN || 0,
                    ],

                    [
                        t("Failing"),
                      activeHealthCounts.FAIL || 0,
                      inactiveHealthCounts.FAIL || 0,
                      totalHealthCounts.FAIL || 0,
                    ],

                    [
                        t("Passing"),
                      activeHealthCounts.PASS || 0,
                      inactiveHealthCounts.PASS || 0,
                      totalHealthCounts.PASS || 0,
                    ],
                    [
                        t("Graduated"),
                        activeGraduatedCount,
                        inactiveGraduatedCount,
                        totalGraduatedCount
                    ],
                    [
                        m("b", t("Sum")),
                        activeDevices.length,
                        inactiveDevices.length,
                        activeDevices.length + inactiveDevices.length
                    ]

                ]),
            deviceList(t("Unknown"), true, deviceHealthGroups.UNKNOWN),
            deviceList(t("Failing"), true, deviceHealthGroups.FAIL),
            deviceList(t("Passing"), false, deviceHealthGroups.PASS)
        ];
    }

};
