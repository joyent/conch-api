var m = require("mithril");
var t = require("i18n4v");
var R = require("ramda");

var Device = require("../models/Device");
var Relay = require("../models/Relay");
var Rack = require("../models/Rack");

var Icons = require("./component/Icons");
var Table = require("./component/Table");

import RackProgress from "./Status/RackProgress";

function deviceList(title, isProblem, devices) {
    var linkPrefix = isProblem ? "/problem/" : "/device/";
    return m(
        ".pure-u-1.pure-u-sm-1-3.text-center",
        m("h2", title),
        devices
            ? m(
                  ".status-device-list",
                  devices.map(function(device) {
                      return m(
                          "a.status-device-list-item",
                          {
                              href: linkPrefix + device.id,
                              oncreate: m.route.link,
                          },
                          device.id
                      );
                  })
              )
            : m("i", t("No devices"))
    );
}

module.exports = {
    loading: true,
    oninit: ({ state }) => {
        Promise.all([
            Device.loadDevices(),
            Relay.loadActiveRelays(),
            Rack.loadRooms(),
        ]).then(() => (state.loading = false));
    },
    view: function({ state }) {
        if (state.loading) return m(".loading", "Loading...");

        var activeDevices = R.filter(Device.isActive, Device.devices);
        var inactiveDevices = R.filter(
            R.compose(R.not, Device.isActive),
            Device.devices
        );

        var healthCounts = R.countBy(d => {
            if (R.propIs(String, "graduated", d)) return "GRADUATED";
            if (R.propIs(String, "validated", d)) return "VALIDATED";
            return R.prop("health", d);
        });

        var activeHealthCounts = healthCounts(activeDevices);
        var inactiveHealthCounts = healthCounts(inactiveDevices);
        var totalHealthCounts = healthCounts(Device.devices);

        var deviceHealthGroups = R.groupBy(R.prop("health"), Device.devices);
        return [
            m("h1.text-center", "Status"),
            m(
                ".pure-u-1",
                m("h3.text-center", t("Datacenter Rack Build Status"))
            ),
            m(".pure-u-1", m(".text-center", m(RackProgress))),
            Table(
                t("Summary of Device Status"),
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
                        t("Validated"),
                        activeHealthCounts.VALIDATED || 0,
                        inactiveHealthCounts.VALIDATED || 0,
                        totalHealthCounts.VALIDATED || 0,
                    ],

                    [
                        t("Graduated"),
                        activeHealthCounts.GRADUATED || 0,
                        inactiveHealthCounts.GRADUATED || 0,
                        totalHealthCounts.GRADUATED || 0,
                    ],
                    [
                        m("b", t("Sum")),
                        activeDevices.length,
                        inactiveDevices.length,
                        activeDevices.length + inactiveDevices.length,
                    ],
                ]
            ),
            Table(
                t("Active Relays"),
                [t("Name"), t("Devices Connected"), t("Actions")],
                Relay.activeList.map(relay => {
                    return [
                        relay.alias || relay.id,
                        R.filter(Device.isActive, relay.devices).length,
                        [
                            m(
                                "a.pure-button",
                                {
                                    href: `/relay/${relay.id}`,
                                    oncreate: m.route.link,
                                    title: t("Show Relay Details"),
                                },
                                Icons.showRelay
                            ),
                            relay.location
                                ? m(
                                      "a.pure-button",
                                      {
                                          href: `/rack/${relay.location
                                              .rack_id}`,
                                          oncreate: m.route.link,
                                          title: t("Show Connected Rack"),
                                      },
                                      Icons.showRack
                                  )
                                : null,
                        ],
                    ];
                })
            ),
        ];
    },
};
